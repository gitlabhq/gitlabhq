# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentHelper do
  describe '#render_deployment_status' do
    context 'when using a manual deployment' do
      it 'renders a span tag' do
        deploy = build(:deployment, deployable: nil, status: :success)
        html = helper.render_deployment_status(deploy)

        expect(html).to have_css('span.ci-status.ci-success')
      end
    end

    context 'when using a deployment from a build' do
      it 'renders a link tag' do
        deploy = build(:deployment, status: :success)
        html = helper.render_deployment_status(deploy)

        expect(html).to have_css('a.ci-status.ci-success')
      end
    end
  end
end
