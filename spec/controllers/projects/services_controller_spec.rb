require 'spec_helper'

describe Projects::ServicesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:service) { create(:service, project: project) }

  before do
    sign_in(user)
    project.team << [user, :master]
    controller.instance_variable_set(:@project, project)
    controller.instance_variable_set(:@service, service)
  end

  shared_examples_for 'services controller' do |referrer|
    before do
      request.env["HTTP_REFERER"] = referrer
    end

    describe "#test" do
      context 'success' do
        it "should redirect and show success message" do
          expect(service).to receive(:test).and_return({ success: true, result: 'done' })
          get :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, format: :html
          expect(response.status).to redirect_to('/')
          expect(flash[:notice]).to eq('We sent a request to the provided URL')
        end
      end

      context 'failure' do
        it "should redirect and show failure message" do
          expect(service).to receive(:test).and_return({ success: false, result: 'Bad test' })
          get :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, format: :html
          expect(response.status).to redirect_to('/')
          expect(flash[:alert]).to eq('We tried to send a request to the provided URL but an error occurred: Bad test')
        end
      end
    end
  end

  describe 'referrer defined' do
    it_should_behave_like 'services controller' do
      let!(:referrer) { "/" }
    end
  end

  describe 'referrer undefined' do
    it_should_behave_like 'services controller' do
      let!(:referrer) { nil }
    end
  end
end
