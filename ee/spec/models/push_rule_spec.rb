require 'spec_helper'

describe PushRule do
  using RSpec::Parameterized::TableSyntax

  let(:global_push_rule) { create(:push_rule_sample) }
  let(:push_rule) { create(:push_rule) }
  let(:user) { create(:user) }
  let(:project) { Projects::CreateService.new(user, { name: 'test', namespace: user.namespace }).execute }

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_numericality_of(:max_file_size).is_greater_than_or_equal_to(0).only_integer }

    it 'validates RE2 regex syntax' do
      push_rule = build(:push_rule, branch_name_regex: '(ee|ce).*\1')

      expect(push_rule).not_to be_valid
      expect(push_rule.errors.full_messages.join).to match /invalid escape sequence/
    end
  end

  it 'defaults regexp_uses_re2 to true' do
    push_rule = create(:push_rule)

    expect(push_rule.regexp_uses_re2).to eq(true)
  end

  it 'updates regexp_uses_re2 to true on edit' do
    push_rule = create(:push_rule, regexp_uses_re2: nil)

    expect do
      push_rule.update!(branch_name_regex: '.*')
    end.to change(push_rule, :regexp_uses_re2).to true
  end

  describe '#branch_name_allowed?' do
    subject(:push_rule) { create(:push_rule, branch_name_regex: '\d+\-.*')}

    it 'checks branch against regex' do
      expect(subject.branch_name_allowed?('123-feature')).to be true
      expect(subject.branch_name_allowed?('feature-123')).to be false
    end

    it 'uses RE2 regex engine' do
      expect_any_instance_of(Gitlab::UntrustedRegexp).to receive(:===)

      subject.branch_name_allowed?('123-feature')
    end

    context 'with legacy regex' do
      before do
        push_rule.update_column(:regexp_uses_re2, nil)
      end

      it 'attempts to use safe RE2 regex engine' do
        expect_any_instance_of(Gitlab::UntrustedRegexp).to receive(:===)

        subject.branch_name_allowed?('ee-feature-ee')
      end

      it 'falls back to ruby regex engine' do
        push_rule.update_column(:branch_name_regex, '(ee|ce).*\1')

        expect(subject.branch_name_allowed?('ee-feature-ee')).to be true
        expect(subject.branch_name_allowed?('ee-feature-ce')).to be false
      end
    end
  end

  describe '#commit_message_allowed?' do
    subject(:push_rule) { create(:push_rule, commit_message_regex: '^Signed-off-by')}

    it 'uses multiline regex' do
      commit_message = "Some git commit feature\n\nSigned-off-by: Someone"

      expect(subject.commit_message_allowed?(commit_message)).to be true
    end
  end

  describe '#commit_validation?' do
    let(:settings_with_global_default) { %i(reject_unsigned_commits) }

    where(:setting, :value, :result) do
      :commit_message_regex    | 'regex'       | true
      :branch_name_regex       | 'regex'       | true
      :author_email_regex      | 'regex'       | true
      :file_name_regex         | 'regex'       | true
      :reject_unsigned_commits | true          | true
      :commit_committer_check  | true          | true
      :member_check            | true          | true
      :prevent_secrets         | true          | true
      :max_file_size           | 1             | false
    end

    with_them do
      context "when rule is enabled at global level" do
        before do
          global_push_rule.update_column(setting, value)
        end

        it "returns the default value at project level" do
          rule = project.push_rule

          if settings_with_global_default.include?(setting)
            rule.update_column(setting, nil)
          end

          expect(rule.commit_validation?).to eq(result)
        end
      end
    end
  end

  methods_and_regexes = {
    commit_message_allowed?: :commit_message_regex,
    branch_name_allowed?: :branch_name_regex,
    author_email_allowed?: :author_email_regex,
    filename_blacklisted?: :file_name_regex
  }

  methods_and_regexes.each do |method_name, regex_attr|
    describe "##{method_name}" do
      it 'raises a MatchError when the regex is invalid' do
        push_rule[regex_attr] = '+'

        expect { push_rule.public_send(method_name, 'foo') } # rubocop:disable GitlabSecurity/PublicSend
          .to raise_error(PushRule::MatchError, /\ARegular expression '\+' is invalid/)
      end
    end
  end

  describe '#commit_signature_allowed?' do
    let!(:premium_license) { create(:license, plan: License::PREMIUM_PLAN) }
    let(:signed_commit) { double(has_signature?: true) }
    let(:unsigned_commit) { double(has_signature?: false) }

    context 'when feature is not licensed and it is enabled' do
      before do
        stub_licensed_features(reject_unsigned_commits: false)
        global_push_rule.update_attribute(:reject_unsigned_commits, true)
      end

      it 'accepts unsigned commits' do
        expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(true)
      end
    end

    context 'when enabled at a global level' do
      before do
        global_push_rule.update_attribute(:reject_unsigned_commits, true)
      end

      it 'returns false if commit is not signed' do
        expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
      end

      context 'and disabled at a Project level' do
        it 'returns true if commit is not signed' do
          push_rule.update_attribute(:reject_unsigned_commits, false)

          expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(true)
        end
      end

      context 'and unset at a Project level' do
        it 'returns false if commit is not signed' do
          push_rule.update_attribute(:reject_unsigned_commits, nil)

          expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
        end
      end
    end

    context 'when disabled at a global level' do
      before do
        global_push_rule.update_attribute(:reject_unsigned_commits, false)
      end

      it 'returns true if commit is not signed' do
        expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(true)
      end

      context 'but enabled at a Project level' do
        before do
          push_rule.update_attribute(:reject_unsigned_commits, true)
        end

        it 'returns false if commit is not signed' do
          expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
        end

        it 'returns true if commit is signed' do
          expect(push_rule.commit_signature_allowed?(signed_commit)).to eq(true)
        end
      end

      context 'when user has enabled and disabled it at a project level' do
        before do
          # Let's test with the same boolean values that are sent through the form
          push_rule.update_attribute(:reject_unsigned_commits, '1')
          push_rule.update_attribute(:reject_unsigned_commits, '0')
        end

        context 'and it is enabled globally' do
          before do
            global_push_rule.update_attribute(:reject_unsigned_commits, true)
          end

          it 'returns false if commit is not signed' do
            expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
          end

          it 'returns true if commit is signed' do
            expect(push_rule.commit_signature_allowed?(signed_commit)).to eq(true)
          end
        end
      end
    end
  end

  describe '#available?' do
    shared_examples 'an unavailable push_rule' do
      it 'is not available' do
        expect(push_rule.available?(:reject_unsigned_commits)).to eq(false)
      end
    end

    shared_examples 'an available push_rule' do
      it 'is available' do
        expect(push_rule.available?(:reject_unsigned_commits)).to eq(true)
      end
    end

    describe 'reject_unsigned_commits' do
      context 'with the global push_rule' do
        let(:push_rule) { create(:push_rule_sample) }

        context 'with a EE starter license' do
          let!(:license) { create(:license, plan: License::STARTER_PLAN) }

          it_behaves_like 'an unavailable push_rule'
        end

        context 'with a EE premium license' do
          let!(:license) { create(:license, plan: License::PREMIUM_PLAN) }

          it_behaves_like 'an available push_rule'
        end
      end

      context 'with GL.com plans' do
        let(:group) { create(:group, plan: plan) }
        let(:project) { create(:project, namespace: group) }
        let(:push_rule) { create(:push_rule, project: project) }

        before do
          create(:license, plan: License::PREMIUM_PLAN)
          stub_application_setting(check_namespace_plan: true)
        end

        context 'with a Bronze plan' do
          let(:plan) { :bronze_plan }

          it_behaves_like 'an unavailable push_rule'
        end

        context 'with a Silver plan' do
          let(:plan) { :silver_plan }

          it_behaves_like 'an available push_rule'
        end

        context 'with a Gold plan' do
          let(:plan) { :gold_plan }

          it_behaves_like 'an available push_rule'
        end
      end
    end
  end
end
