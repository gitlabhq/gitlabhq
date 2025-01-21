# frozen_string_literal: true

require 'rspec'

require 'spec_helper'
require 'mime/types'

RSpec.describe Projects::Ml::ModelRegistryHelper, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:user) { project.first_owner }

  describe '#index_ml_model_data' do
    subject(:parsed) { Gitlab::Json.parse(helper.index_ml_model_data(project, user)) }

    it 'generates the correct data' do
      stub_member_access_level(project, owner: user)

      is_expected.to eq({
        'projectPath' => project.full_path,
        'createModelPath' => "/#{project.full_path}/-/ml/models/new",
        'canWriteModelRegistry' => true,
        'maxAllowedFileSize' => 10737418240,
        'mlflowTrackingUrl' => "http://localhost/api/v4/projects/#{project.id}/ml/mlflow/",
        'markdownPreviewPath' => "/#{project.full_path}/-/preview_markdown"
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end

  describe '#new_ml_model_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, name: 'cool_model')
    end

    subject(:parsed) { Gitlab::Json.parse(helper.new_ml_model_data(project, user)) }

    it 'generates the correct data' do
      stub_member_access_level(project, owner: user)

      is_expected.to eq({
        'indexModelsPath' => "/#{project.full_path}/-/ml/models",
        'projectPath' => project.full_path,
        'canWriteModelRegistry' => true,
        'markdownPreviewPath' => "/#{project.full_path}/-/preview_markdown"
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end

  describe '#show_ml_model_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, name: 'cool_model')
    end

    subject(:parsed) { Gitlab::Json.parse(helper.show_ml_model_data(model, user)) }

    it 'generates the correct data' do
      stub_member_access_level(project, owner: user)

      is_expected.to eq({
        'projectPath' => project.full_path,
        'indexModelsPath' => "/#{project.full_path}/-/ml/models",
        'editModelPath' => "/#{project.full_path}/-/ml/models/#{model.id}/edit",
        'createModelVersionPath' => "/#{project.full_path}/-/ml/models/#{model.id}/versions/new",
        'canWriteModelRegistry' => true,
        'maxAllowedFileSize' => 10737418240,
        'mlflowTrackingUrl' => "http://localhost/api/v4/projects/#{project.id}/ml/mlflow/",
        'modelId' => model.id,
        'modelName' => 'cool_model',
        'latestVersion' => model.latest_version.version,
        'markdownPreviewPath' => "/#{project.full_path}/-/preview_markdown"
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end

    context 'when no user' do
      let_it_be(:user) { nil }

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(nil)
      end
    end
  end

  describe '#edit_ml_model_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, name: 'cool_model',
        description: 'desc')
    end

    subject(:parsed) { Gitlab::Json.parse(helper.edit_ml_model_data(model, user)) }

    it 'generates the correct data' do
      stub_member_access_level(project, owner: user)

      is_expected.to eq({
        'projectPath' => project.full_path,
        'canWriteModelRegistry' => true,
        'markdownPreviewPath' => "/#{project.full_path}/-/preview_markdown",
        'modelPath' => "/#{project.full_path}/-/ml/models/#{model.id}",
        'modelId' => model.id,
        'modelName' => 'cool_model',
        'modelDescription' => 'desc'
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end

  describe '#new_ml_model_version_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, id: 1)
    end

    subject(:parsed) { Gitlab::Json.parse(helper.new_ml_model_version_data(model, user)) }

    it 'generates the correct data' do
      stub_member_access_level(project, owner: user)

      is_expected.to eq({
        'modelPath' => "/#{project.full_path}/-/ml/models/#{model.id}",
        "projectPath" => project.full_path,
        "canWriteModelRegistry" => true,
        'maxAllowedFileSize' => 10737418240,
        "modelGid" => model.to_global_id.to_s,
        "markdownPreviewPath" => "/#{project.full_path}/-/preview_markdown"
      })
    end
  end

  describe '#show_ml_model_version_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, id: 1)
    end

    let_it_be(:model_version) do
      model.latest_version
    end

    subject(:parsed) { Gitlab::Json.parse(helper.show_ml_model_version_data(model_version, user)) }

    it 'generates the correct data' do
      stub_member_access_level(project, owner: user)

      is_expected.to eq({
        "projectPath" => project.full_path,
        "modelId" => model.id,
        "modelVersionId" => model_version.id,
        "modelName" => model_version.name,
        "versionName" => model_version.version,
        "canWriteModelRegistry" => true,
        'maxAllowedFileSize' => 10737418240,
        "importPath" => "/api/v4/projects/#{project.id}/packages/ml_models/#{model_version.id}/files/",
        "modelPath" => "/#{project.full_path}/-/ml/models/1",
        "editModelVersionPath" => "/#{project.full_path}/-/ml/models/1/versions/#{model_version.id}/edit",
        "markdownPreviewPath" => "/#{project.full_path}/-/preview_markdown"
      })
    end
  end

  describe '#edit_ml_model_version_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, id: 1)
    end

    let_it_be(:model_version) do
      model.latest_version
    end

    subject(:parsed) { Gitlab::Json.parse(helper.edit_ml_model_version_data(model_version, user)) }

    it 'generates the correct data' do
      stub_member_access_level(project, owner: user)

      is_expected.to eq({
        "projectPath" => project.full_path,
        "canWriteModelRegistry" => true,
        "markdownPreviewPath" => "/#{project.full_path}/-/preview_markdown",
        "modelVersionPath" => "/#{project.full_path}/-/ml/models/1/versions/#{model_version.id}",
        "modelGid" => model.to_global_id.to_s,
        "modelVersionDescription" => model_version.description,
        "modelVersionVersion" => model_version.version
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end
end
