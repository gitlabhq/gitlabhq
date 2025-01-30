# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KeysFinder do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new(params).execute }

  let_it_be(:user) { create(:user) }
  let_it_be(:key_1) do
    create(:rsa_key_4096,
      created_at: 10.days.ago,
      last_used_at: 7.days.ago,
      user: user,
      fingerprint: 'df:73:db:29:3c:a5:32:cf:09:17:7e:8e:9d:de:d7:f7',
      fingerprint_sha256: 'ByDU7hQ1JB95l6p53rHrffc4eXvEtqGUtQhS+Dhyy7g')
  end

  let_it_be(:key_2) { create(:personal_key_4096, last_used_at: nil, user: user) }
  let_it_be(:key_3) { create(:personal_key_4096, created_at: 3.days.ago, last_used_at: 2.days.ago) }

  let(:params) { {} }

  context 'key_type' do
    let_it_be(:deploy_key) { create(:deploy_key) }

    context 'when `key_type` is `ssh`' do
      before do
        params[:key_type] = 'ssh'
      end

      it 'returns only SSH keys' do
        expect(subject).to contain_exactly(key_1, key_2, key_3)
      end
    end

    context 'when `key_type` is not specified' do
      it 'returns all types of keys' do
        expect(subject).to contain_exactly(key_1, key_2, key_3, deploy_key)
      end
    end
  end

  context 'fingerprint' do
    context 'with invalid fingerprint' do
      context 'with invalid MD5 fingerprint' do
        before do
          params[:fingerprint] = '11:11:11:11'
        end

        it 'raises InvalidFingerprint' do
          expect { subject }.to raise_error(KeysFinder::InvalidFingerprint)
        end
      end

      context 'with invalid SHA fingerprint' do
        before do
          params[:fingerprint] = 'nUhzNyftwAAKs7HufskYTte2g'
        end

        it 'raises InvalidFingerprint' do
          expect { subject }.to raise_error(KeysFinder::InvalidFingerprint)
        end
      end
    end

    context 'with valid fingerprints' do
      let_it_be(:deploy_key) { create(:rsa_deploy_key_5120, user: user) }

      context 'personal key with valid MD5 params' do
        context 'with an existent fingerprint' do
          before do
            params[:fingerprint] = 'df:73:db:29:3c:a5:32:cf:09:17:7e:8e:9d:de:d7:f7'
          end

          it 'returns the key' do
            expect(subject).to eq(key_1)
            expect(subject.user).to eq(user)
          end

          context 'with FIPS mode', :fips_mode do
            it 'raises InvalidFingerprint' do
              expect { subject }.to raise_error(KeysFinder::InvalidFingerprint)
            end
          end
        end

        context 'deploy key with an existent fingerprint' do
          before do
            params[:fingerprint] = 'fe:fa:3a:4d:7d:51:ec:bf:c7:64:0c:96:d0:17:8a:d0'
          end

          it 'returns the key' do
            expect(subject).to eq(deploy_key)
            expect(subject.user).to eq(user)
          end

          context 'with FIPS mode', :fips_mode do
            it 'raises InvalidFingerprint' do
              expect { subject }.to raise_error(KeysFinder::InvalidFingerprint)
            end
          end
        end

        context 'with a non-existent fingerprint' do
          before do
            params[:fingerprint] = 'bb:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d2'
          end

          it 'returns nil' do
            expect(subject).to be_nil
          end

          context 'with FIPS mode', :fips_mode do
            it 'raises InvalidFingerprint' do
              expect { subject }.to raise_error(KeysFinder::InvalidFingerprint)
            end
          end
        end
      end

      context 'personal key with valid SHA256 params' do
        context 'with an existent fingerprint' do
          before do
            params[:fingerprint] = 'SHA256:ByDU7hQ1JB95l6p53rHrffc4eXvEtqGUtQhS+Dhyy7g'
          end

          it 'returns key' do
            expect(subject).to eq(key_1)
            expect(subject.user).to eq(user)
          end
        end

        context 'deploy key with an existent fingerprint' do
          before do
            params[:fingerprint] = 'SHA256:PCCupLbFHScm4AbEufbGDvhBU27IM0MVAor715qKQK8'
          end

          it 'returns key' do
            expect(subject).to eq(deploy_key)
            expect(subject.user).to eq(user)
          end
        end

        context 'with a non-existent fingerprint' do
          before do
            params[:fingerprint] = 'SHA256:xTjuFqftwADy8AH3wFY31tAKs7HufskYTte2aXi/mNp'
          end

          it 'returns nil' do
            expect(subject).to be_nil
          end
        end
      end
    end
  end

  context 'user' do
    context 'without user' do
      it 'contains ssh_keys of all users in the system' do
        expect(subject).to contain_exactly(key_1, key_2, key_3)
      end
    end

    context 'with user' do
      before do
        params[:users] = user
      end

      it 'contains ssh_keys of only the specified users' do
        expect(subject).to contain_exactly(key_1, key_2)
      end
    end
  end

  describe 'by created before' do
    where(:by_created_before, :expected_keys) do
      1.day.ago        | [ref(:key_1), ref(:key_3)]
      10.days.from_now | [ref(:key_1), ref(:key_2), ref(:key_3)]
    end

    with_them do
      let(:params) { { created_before: by_created_before } }

      it 'returns keys by expires before' do
        is_expected.to match_array(expected_keys)
      end
    end
  end

  describe 'by created after' do
    where(:by_created_after, :expected_keys) do
      11.days.ago | [ref(:key_1), ref(:key_2), ref(:key_3)]
      1.day.ago   | [ref(:key_2)]
    end

    with_them do
      let(:params) { { created_after: by_created_after } }

      it 'returns tokens by expires after' do
        is_expected.to match_array(expected_keys)
      end
    end
  end

  describe 'expires at filters' do
    let_it_be(:expired_key) { create(:personal_key_4096, :expired) }
    let_it_be(:expires_in_future_key) { create(:personal_key_4096, expires_at: 30.days.from_now) }

    # Init
    before_all do
      expired_key
      expires_in_future_key
    end

    describe 'by expires before' do
      where(:by_expires_before, :expected_keys) do
        1.day.ago        | [ref(:expired_key)]
        31.days.from_now | [ref(:expired_key), ref(:expires_in_future_key)]
      end

      with_them do
        let(:params) { { expires_before: by_expires_before } }

        it 'returns keys by expires before' do
          is_expected.to match_array(expected_keys)
        end
      end
    end

    describe 'by expires after' do
      where(:by_expires_after, :expected_keys) do
        2.days.ago       | [ref(:expired_key), ref(:expires_in_future_key)]
        30.days.from_now | [ref(:expires_in_future_key)]
      end

      with_them do
        let(:params) { { expires_after: by_expires_after } }

        it 'returns tokens by expires after' do
          is_expected.to match_array(expected_keys)
        end
      end
    end
  end

  context 'sort order' do
    it 'sorts in last_used_at_desc order' do
      expect(subject).to eq([key_3, key_1, key_2])
    end
  end
end
