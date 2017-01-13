module API
  class NoteTemplates < Grape::API
    before { authenticate! }

    resource :note_templates
      desc 'Get global notification level settings and email, defaults to Participate' do
        success Entities::NoteTemplates
      end
      get do
        
      end
      put do
        
      end
  end
end
