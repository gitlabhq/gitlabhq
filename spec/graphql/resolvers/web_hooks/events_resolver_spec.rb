# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WebHooks::EventsResolver, :freeze_time, feature_category: :webhooks do
  include GraphqlHelpers

  describe '#resolve' do
    context 'when resolving web hook logs on a project hook' do
      let_it_be(:web_hook) { create(:project_hook) }
      let_it_be(:authorized_user) { create(:user, maintainer_of: web_hook.project) }
      let_it_be(:unauthorized_user) { create(:user, developer_of: web_hook.project) }

      it_behaves_like 'resolving web hook logs'
    end
  end
end
