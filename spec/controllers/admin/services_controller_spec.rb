require 'spec_helper'

describe Admin::ServicesController do
  let(:admin) { create(:admin) }

  before { sign_in(admin) }

  describe 'GET #edit' do
    let!(:project) { create(:empty_project) }

    Service.available_services_names.each do |service_name|
      context "#{service_name}" do
        let!(:service) do
          service_template = service_name.concat("_service").camelize.constantize
          service_template.where(template: true).first_or_create
        end

        it 'successfully displays the template' do
          get :edit, id: service.id

          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
