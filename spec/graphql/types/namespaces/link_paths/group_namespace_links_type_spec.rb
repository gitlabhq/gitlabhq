# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::LinkPaths::GroupNamespaceLinksType, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :notification_email) }

  it_behaves_like "expose all link paths fields for the namespace"

  shared_examples "group namespace link paths values" do
    it_behaves_like "common namespace link paths values"

    where(:field, :value) do
      :issues_list | lazy { "/groups/#{namespace.full_path}/-/issues" }
      :labels_manage | lazy { "/groups/#{namespace.full_path}/-/labels" }
      :new_project | lazy { "/projects/new?namespace_id=#{namespace.id}" }
      :new_comment_template | [{ href: "/-/profile/comment_templates", text: "Your comment templates" }]
      :user_export_email | lazy { user.notification_email_or_default }
      :namespace_full_path | lazy { namespace.full_path }
      :group_path | lazy { namespace.full_path }
      :issues_list_path | lazy { "/groups/#{namespace.full_path}/-/issues" }
    end

    with_them do
      it "expects to return the right value" do
        expect(resolve_field(field, namespace, current_user: user)).to eq(value)
      end
    end

    it 'returns rss_path with feed token' do
      path = resolve_field(:rss_path, namespace, current_user: user)
      expect(path).to match(
        %r{^/groups/#{Regexp.escape(namespace.full_path)}/-/work_items\.atom\?feed_token=glft-.+-#{user.id}$}
      )
    end

    it 'returns calendar_path with feed token' do
      path = resolve_field(:calendar_path, namespace, current_user: user)
      expect(path).to match(
        %r{^/groups/#{Regexp.escape(namespace.full_path)}/-/work_items\.ics\?feed_token=glft-.+-#{user.id}$}
      )
    end
  end

  context "when fetching public group" do
    let_it_be(:namespace) { create(:group, :nested, :public, developers: user) }

    it_behaves_like "group namespace link paths values"
  end

  context "when fetching private group" do
    let_it_be(:namespace) { create(:group, :nested, :private) }

    context "when user is not member of the group" do
      it_behaves_like "group namespace link paths values"
    end

    context "when user is member of the group" do
      before_all do
        namespace.add_developer(user)
      end

      it_behaves_like "group namespace link paths values"
    end
  end
end
