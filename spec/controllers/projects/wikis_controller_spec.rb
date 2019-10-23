# frozen_string_literal: true

require 'spec_helper'

describe Projects::WikisController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { project.owner }
  let_it_be(:project_wiki) { ProjectWiki.new(project, user) }
  let_it_be(:wiki) { project_wiki.wiki }
  let_it_be(:wiki_title) { 'page title test' }

  before do
    create_page(wiki_title, 'hello world')

    sign_in(user)
  end

  after do
    destroy_page(wiki_title)
  end

  describe 'GET #pages' do
    subject do
      get :pages, params: { namespace_id: project.namespace, project_id: project, id: wiki_title }.merge(extra_params)
    end

    let(:extra_params) { {} }

    it 'does not load the pages content' do
      expect(controller).to receive(:load_wiki).and_return(project_wiki)
      expect(project_wiki).to receive(:list_pages).twice.and_call_original

      subject
    end

    describe 'illegal params' do
      shared_examples :a_bad_request do
        it do
          expect { subject }.to raise_error(ActionController::BadRequest)
        end
      end

      describe ':sort' do
        let(:extra_params) { { sort: 'wibble' } }

        it_behaves_like :a_bad_request
      end

      describe ':direction' do
        let(:extra_params) { { direction: 'wibble' } }

        it_behaves_like :a_bad_request
      end

      describe ':show_children' do
        let(:extra_params) { { show_children: 'wibble' } }

        it_behaves_like :a_bad_request
      end
    end

    shared_examples 'sorting-and-nesting' do |sort_key, default_nesting|
      context "the user is sorting by #{sort_key}" do
        let(:extra_params) { sort_params.merge(nesting_params) }
        let(:sort_params) { { sort: sort_key } }
        let(:nesting_params) { {} }

        before do
          subject
        end

        it "sets nesting to #{default_nesting} by default" do
          expect(assigns :nesting).to eq default_nesting
        end

        it 'hides children if the default requires it' do
          expect(assigns :show_children).to be(default_nesting != ProjectWiki::NESTING_CLOSED)
        end

        ProjectWiki::NESTINGS.each do |nesting|
          context "the user explicitly passes show_children = #{nesting}" do
            let(:nesting_params) { { show_children: nesting } }

            it 'sets nesting to the provided value' do
              expect(assigns :nesting).to eq nesting
            end
          end
        end

        context 'the user wants children hidden' do
          let(:nesting_params) { { show_children: 'hidden' } }

          it 'hides children' do
            expect(assigns :show_children).to be false
          end
        end
      end
    end

    include_examples 'sorting-and-nesting', ProjectWiki::CREATED_AT_ORDER, ProjectWiki::NESTING_FLAT
    include_examples 'sorting-and-nesting', ProjectWiki::TITLE_ORDER, ProjectWiki::NESTING_CLOSED
  end

  def create_page(name, content)
    wiki.write_page(name, :markdown, content, commit_details(name))
  end

  def commit_details(name)
    Gitlab::Git::Wiki::CommitDetails.new(user.id, user.username, user.name, user.email, "created page #{name}")
  end

  def destroy_page(title, dir = '')
    page = wiki.page(title: title, dir: dir)
    project_wiki.delete_page(page, "test commit")
  end
end
