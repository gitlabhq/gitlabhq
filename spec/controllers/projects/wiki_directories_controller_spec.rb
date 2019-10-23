# frozen_string_literal: true

require 'spec_helper'

describe Projects::WikiDirectoriesController do
  set(:project) { create(:project, :public, :repository) }

  let(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  let(:wiki) { project_wiki.wiki }
  let(:dir_slug) { 'the-directory' }
  let(:dir_contents) { [create(:wiki_page)] }
  let(:the_dir) { WikiDirectory.new(dir_slug, dir_contents) }

  before do
    allow(controller).to receive(:find_dir).and_return(the_dir)

    sign_in(user)
  end

  describe 'GET #show' do
    let(:show_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: dir_slug
      }
    end

    before do
      get :show, params: show_params
    end

    context 'the directory is empty' do
      let(:the_dir) { nil }

      it { is_expected.to render_template('empty') }
    end

    context 'the directory does exist' do
      it { is_expected.to render_template('show') }

      it 'sets the wiki_dir attribute' do
        expect(assigns(:wiki_dir)).to eq(the_dir)
      end

      it 'assigns the wiki pages' do
        expect(assigns(:wiki_pages)).to eq(dir_contents)
      end
    end
  end
end
