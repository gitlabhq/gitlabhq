import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/ml/model_registry/components/model_list_empty_state.vue';
import { MLFLOW_USAGE_MODAL_ID } from '~/ml/model_registry/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

let wrapper;
const createWrapper = () => {
  wrapper = shallowMount(EmptyState, {
    provide: { mlflowTrackingUrl: 'path/to/mlflow' },
    propsData: {
      primaryText: 'primary-text',
      primaryLink: 'primary/link',
      title: 'title',
      description: 'description',
    },
    directives: {
      GlModal: createMockDirective('gl-modal'),
    },
  });
};

const findEmptyState = () => wrapper.findComponent(GlEmptyState);
const findCreateButton = () => wrapper.findComponent(GlButton);
const findDocsButton = () => wrapper.findAllComponents(GlButton).at(1);

describe('ml/model_registry/components/model_list_empty_state.vue', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('renders empty state', () => {
    expect(findEmptyState().props()).toMatchObject({
      title: 'title',
      svgPath: 'file-mock',
      description: 'description',
    });
  });

  it('creates button to open model creation', () => {
    expect(findCreateButton().text()).toBe('primary-text');
    expect(findCreateButton().attributes('href')).toBe('primary/link');
  });

  it('creates button to docs', () => {
    expect(findDocsButton().text()).toBe('Create using MLflow');
    expect(getBinding(findDocsButton().element, 'gl-modal').value).toBe(MLFLOW_USAGE_MODAL_ID);
  });
});
