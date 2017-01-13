module API
  class NoteTemplates < Grape::API
    include PaginationParams

    before { authenticate! }

    resource :note_templates do
      desc 'Get all note templates for the authenticated user' do
        success Entities::NoteTemplate
      end
      get do
        NoteTemplate.all
      end

      desc 'Get a note templates for the authenticated user' do
        success Entities::NoteTemplate
      end
      params do
        requires :id, type: Integer, desc: "The ID of the note template."
      end
      get "note_templates/:id" do
        note_template = NoteTemplate.find_by(id: params[:id])

        present note_template, with: Entities::NoteTemplate
      end

      desc 'Create a note template for the authenticated user' do
        success Entities::NoteTemplate
      end
      params do
        requires :title, type: String, desc: "The title of the note template."
        requires :note, type: String, desc: "The body of the note template."
      end
      post do
        note_template = NoteTemplate.create!(declared(params, include_parent_namespaces: false).to_h)

        present note_template, with: Entities::NoteTemplate, current_user: current_user
      end

      desc 'Update a note template for the authenticated user' do
        success Entities::NoteTemplate
      end
      params do
        requires :id, type: Integer, desc: "The ID of the note template."
        optional :title, type: String, desc: "The title of the note template."
        optional :note, type: String, desc: "The body of the note template."
        at_least_one_of :title, :note
      end
      put "note_templates/:id" do
        note_template = NoteTemplate.find(params[:id])
        
        note_template.update_attributes(declared(params, include_parent_namespaces: false).to_h)

        present note_template, with: Entities::NoteTemplate
      end

      desc 'Delete a note template for the authenticated user' do
        success Entities::NoteTemplate
      end
      params do
        requires :id, type: Integer, desc: "The ID of the note template."
      end
      delete "note_templates/:id" do
        puts 'test'
      end
    end
  end
end
