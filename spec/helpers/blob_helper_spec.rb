# frozen_string_literal: true

require 'spec_helper'

describe BlobHelper do
  include TreeHelper

  describe '#highlight' do
    it 'wraps highlighted content' do
      expect(helper.highlight('test.rb', '52')).to eq(%q[<pre class="code highlight"><code><span id="LC1" class="line" lang="ruby"><span class="mi">52</span></span></code></pre>])
    end

    it 'handles plain version' do
      expect(helper.highlight('test.rb', '52', plain: true)).to eq(%q[<pre class="code highlight"><code><span id="LC1" class="line" lang="">52</span></code></pre>])
    end
  end

  describe "#sanitize_svg_data" do
    let(:input_svg_path) { File.join(Rails.root, 'spec', 'fixtures', 'unsanitized.svg') }
    let(:data) { File.read(input_svg_path) }
    let(:expected_svg_path) { File.join(Rails.root, 'spec', 'fixtures', 'sanitized.svg') }
    let(:expected) { File.read(expected_svg_path) }

    it 'retains essential elements' do
      expect(sanitize_svg_data(data)).to eq(expected)
    end
  end

  describe "#edit_blob_link" do
    let(:namespace) { create(:namespace, name: 'gitlab' )}
    let(:project) { create(:project, :repository, namespace: namespace) }

    before do
      allow(helper).to receive(:current_user).and_return(nil)
      allow(helper).to receive(:can?).and_return(true)
      allow(helper).to receive(:can_collaborate_with_project?).and_return(true)
    end

    it 'verifies blob is text' do
      expect(helper).not_to receive(:blob_text_viewable?)

      button = helper.edit_blob_button(project, 'refs/heads/master', 'README.md')

      expect(button).to start_with('<button')
    end

    it 'uses the passed blob instead retrieve from repository' do
      blob = project.repository.blob_at('refs/heads/master', 'README.md')

      expect(project.repository).not_to receive(:blob_at)

      helper.edit_blob_button(project, 'refs/heads/master', 'README.md', blob: blob)
    end

    it 'returns a link with the proper route' do
      stub_feature_flags(web_ide_default: false)
      link = helper.edit_blob_button(project, 'master', 'README.md')

      expect(Capybara.string(link).find_link('Edit')[:href]).to eq("/#{project.full_path}/-/edit/master/README.md")
    end

    it 'returns a link with a Web IDE route' do
      link = helper.edit_blob_button(project, 'master', 'README.md')

      expect(Capybara.string(link).find_link('Edit')[:href]).to eq("/-/ide/project/#{project.full_path}/edit/master/-/README.md")
    end

    it 'returns a link with the passed link_opts on the expected route' do
      stub_feature_flags(web_ide_default: false)
      link = helper.edit_blob_button(project, 'master', 'README.md', link_opts: { mr_id: 10 })

      expect(Capybara.string(link).find_link('Edit')[:href]).to eq("/#{project.full_path}/-/edit/master/README.md?mr_id=10")
    end
  end

  context 'viewer related' do
    include FakeBlobHelpers

    let(:project) { build(:project, lfs_enabled: true) }

    before do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
    end

    let(:viewer_class) do
      Class.new(BlobViewer::Base) do
        include BlobViewer::ServerSide

        self.collapse_limit = 1.megabyte
        self.size_limit = 5.megabytes
        self.type = :rich
      end
    end

    let(:viewer) { viewer_class.new(blob) }
    let(:blob) { fake_blob }

    describe '#blob_render_error_reason' do
      context 'for error :too_large' do
        context 'when the blob size is larger than the absolute size limit' do
          let(:blob) { fake_blob(size: 10.megabytes) }

          it 'returns an error message' do
            expect(helper.blob_render_error_reason(viewer)).to eq('it is larger than 5 MB')
          end
        end

        context 'when the blob size is larger than the size limit' do
          let(:blob) { fake_blob(size: 2.megabytes) }

          it 'returns an error message' do
            expect(helper.blob_render_error_reason(viewer)).to eq('it is larger than 1 MB')
          end
        end
      end

      context 'for error :server_side_but_stored_externally' do
        let(:blob) { fake_blob(lfs: true) }

        it 'returns an error message' do
          expect(helper.blob_render_error_reason(viewer)).to eq('it is stored in LFS')
        end
      end
    end

    describe '#blob_render_error_options' do
      before do
        assign(:project, project)
        assign(:blob, blob)
        assign(:id, File.join('master', blob.path))

        controller.params[:controller] = 'projects/blob'
        controller.params[:action] = 'show'
        controller.params[:namespace_id] = project.namespace.to_param
        controller.params[:project_id] = project.to_param
        controller.params[:id] = File.join('master', blob.path)
      end

      context 'for error :collapsed' do
        let(:blob) { fake_blob(size: 2.megabytes) }

        it 'includes a "load it anyway" link' do
          expect(helper.blob_render_error_options(viewer)).to include(/load it anyway/)
        end
      end

      context 'for error :too_large' do
        let(:blob) { fake_blob(size: 10.megabytes) }

        it 'does not include a "load it anyway" link' do
          expect(helper.blob_render_error_options(viewer)).not_to include(/load it anyway/)
        end

        context 'when the viewer is rich' do
          context 'the blob is rendered as text' do
            let(:blob) { fake_blob(path: 'file.md', size: 2.megabytes) }

            it 'includes a "view the source" link' do
              expect(helper.blob_render_error_options(viewer)).to include(/view the source/)
            end
          end

          context 'the blob is not rendered as text' do
            let(:blob) { fake_blob(path: 'file.pdf', binary: true, size: 2.megabytes) }

            it 'does not include a "view the source" link' do
              expect(helper.blob_render_error_options(viewer)).not_to include(/view the source/)
            end
          end
        end

        context 'when the viewer is not rich' do
          before do
            viewer_class.type = :simple
          end

          let(:blob) { fake_blob(path: 'file.md', size: 2.megabytes) }

          it 'does not include a "view the source" link' do
            expect(helper.blob_render_error_options(viewer)).not_to include(/view the source/)
          end
        end

        it 'includes a "download it" link' do
          expect(helper.blob_render_error_options(viewer)).to include(/download it/)
        end
      end

      context 'for error :server_side_but_stored_externally' do
        let(:blob) { fake_blob(path: 'file.md', lfs: true) }

        it 'does not include a "load it anyway" link' do
          expect(helper.blob_render_error_options(viewer)).not_to include(/load it anyway/)
        end

        it 'does not include a "view the source" link' do
          expect(helper.blob_render_error_options(viewer)).not_to include(/view the source/)
        end

        it 'includes a "download it" link' do
          expect(helper.blob_render_error_options(viewer)).to include(/download it/)
        end
      end
    end
  end

  describe '#ide_edit_path' do
    let(:project) { create(:project) }
    let(:current_user) { create(:user) }
    let(:can_push_code) { true }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(can_push_code)
    end

    around do |example|
      old_script_name = Rails.application.routes.default_url_options[:script_name]
      begin
        example.run
      ensure
        Rails.application.routes.default_url_options[:script_name] = old_script_name
      end
    end

    it 'returns full IDE path' do
      Rails.application.routes.default_url_options[:script_name] = nil

      expect(helper.ide_edit_path(project, "master", "")).to eq("/-/ide/project/#{project.namespace.path}/#{project.path}/edit/master")
    end

    it 'returns full IDE path with second -' do
      Rails.application.routes.default_url_options[:script_name] = nil

      expect(helper.ide_edit_path(project, "testing/slashes", "readme.md")).to eq("/-/ide/project/#{project.namespace.path}/#{project.path}/edit/testing/slashes/-/readme.md")
    end

    it 'returns IDE path without relative_url_root' do
      Rails.application.routes.default_url_options[:script_name] = "/gitlab"

      expect(helper.ide_edit_path(project, "master", "")).to eq("/gitlab/-/ide/project/#{project.namespace.path}/#{project.path}/edit/master")
    end

    it 'escapes special characters' do
      Rails.application.routes.default_url_options[:script_name] = nil

      expect(helper.ide_edit_path(project, "testing/#hashes", "readme.md#test")).to eq("/-/ide/project/#{project.namespace.path}/#{project.path}/edit/testing/#hashes/-/readme.md%23test")
      expect(helper.ide_edit_path(project, "testing/#hashes", "src#/readme.md#test")).to eq("/-/ide/project/#{project.namespace.path}/#{project.path}/edit/testing/#hashes/-/src%23/readme.md%23test")
    end

    it 'does not escape "/" character' do
      Rails.application.routes.default_url_options[:script_name] = nil

      expect(helper.ide_edit_path(project, "testing/slashes", "readme.md/")).to eq("/-/ide/project/#{project.namespace.path}/#{project.path}/edit/testing/slashes/-/readme.md/")
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'returns IDE path inside the project' do
        expect(helper.ide_edit_path(project, "master", "")).to eq("/-/ide/project/#{project.namespace.path}/#{project.path}/edit/master")
      end
    end

    context 'when user cannot push to the project' do
      let(:can_push_code) { false }

      it "returns IDE path with the user's fork" do
        expect(helper.ide_edit_path(project, "master", "")).to eq("/-/ide/project/#{current_user.namespace.full_path}/#{project.path}/edit/master")
      end
    end
  end

  describe '#ide_fork_and_edit_path' do
    let(:project) { create(:project) }
    let(:current_user) { create(:user) }
    let(:can_push_code) { true }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper).to receive(:can?).and_return(can_push_code)
    end

    it 'returns path to fork the repo with a redirect param to the full IDE path' do
      uri = URI(helper.ide_fork_and_edit_path(project, "master", ""))
      params = CGI.unescape(uri.query)

      expect(uri.path).to eq("/#{project.namespace.path}/#{project.path}/-/forks")
      expect(params).to include("continue[to]=/-/ide/project/#{project.namespace.path}/#{project.path}/edit/master")
      expect(params).to include("namespace_key=#{current_user.namespace.id}")
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'returns nil' do
        expect(helper.ide_fork_and_edit_path(project, "master", "")).to be_nil
      end
    end
  end
end
