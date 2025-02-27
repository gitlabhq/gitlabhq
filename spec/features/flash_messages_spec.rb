# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Flash message", :js, feature_category: :design_system do
  let_it_be(:user) { create(:user) }
  let(:flash_text) { %q(it is <i>"HTML"</i> by 'design') }

  # For convenience, we piggy back on existing controller so we don't need
  # to tweak Rails routes.
  let(:test_controller) do
    Class.new(ApplicationController) do
      include SafeFormatHelper

      def kill
        flash[params[:flash_type]] = safe_format(params[:flash_text])

        render inline: 'rendering flash', layout: true # rubocop:disable Rails/RenderInline -- It's fine to render inline in specs.
      end
    end
  end

  subject(:request) { visit kill_chaos_path flash_type: flash_type, flash_text: flash_text }

  before do
    stub_const('ChaosController', test_controller)

    sign_in(user)
  end

  describe 'notice' do
    let(:flash_type) { :notice }

    it 'renders flash as escaped HTML' do
      request

      expect(page.find('.gl-alert-info')).to have_content(flash_text)
    end
  end

  describe 'toast' do
    let(:flash_type) { :toast }

    it 'renders flash as plain text' do
      request

      expect(page.find('[role="status"]')).to have_content(flash_text)
    end
  end
end
