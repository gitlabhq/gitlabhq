require 'spec_helper'

describe CiVariables do
  let(:variable_destroy_params) { { 'id' => '1', 'key' => 'test_key', 'value' => 'test_value', '_destroy' => 'true' } }
  let(:variable_create_params) { { 'id' => '', 'key' => 'test_key', 'value' => 'new_value', '_destroy' => '' } }
  let(:variable_duplicate_params) { { 'id' => '', 'key' => 'test_key', 'value' => 'duplicate_variable', '_destroy' => '' } }
  let(:variable_update_params) { { 'id' => '1', 'key' => 'test_key', 'value' => 'new_value', '_destroy' => '' } }

  let(:controller) do
    klass = Class.new do
      include CiVariables
    end

    controller = klass.new

    allow(controller).to receive(:variables_params).and_return(params)

    controller
  end

  describe '#filtered_variables_params' do
    subject { controller.send(:filtered_variables_params) }

    context 'with both destroy and update params' do
      let(:params) do
        {
          'variables_attributes' =>
          [
            variable_destroy_params,
            variable_create_params
          ]
        }
      end

      it 'merges destroy and create variable params into an update' do
        expect(subject['variables_attributes']).to include(variable_update_params)
      end
    end

    context 'with both destroy and duplicate variable params' do
      let(:params) do
        {
          'variables_attributes' =>
          [
            variable_destroy_params,
            variable_create_params,
            variable_duplicate_params
          ]
        }
      end

      it 'merges destroy and create variable params into an update' do
        expect(subject['variables_attributes']).to include(variable_update_params, variable_duplicate_params)
      end
    end

    context 'with just duplicate create params' do
      let(:params) do
        {
          'variables_attributes' =>
          [
            variable_create_params,
            variable_duplicate_params
          ]
        }
      end

      it 'does not change anything' do
        expect(subject['variables_attributes']).to include(variable_create_params, variable_duplicate_params)
      end
    end
  end
end
