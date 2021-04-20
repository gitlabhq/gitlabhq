import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import ReportsModal from '~/reports/grouped_test_report/components/modal.vue';
import state from '~/reports/grouped_test_report/store/state';
import CodeBlock from '~/vue_shared/components/code_block.vue';

const StubbedGlModal = { template: '<div><slot></slot></div>', name: 'GlModal', props: ['title'] };

describe('Grouped Test Reports Modal', () => {
  const modalDataStructure = state().modal.data;
  const title = 'Test#sum when a is 1 and b is 2 returns summary';

  // populate data
  modalDataStructure.execution_time.value = 0.009411;
  modalDataStructure.system_output.value = 'Failure/Error: is_expected.to eq(3)\n\n';
  modalDataStructure.filename.value = {
    text: 'link',
    path: '/file/path',
  };

  let wrapper;

  beforeEach(() => {
    wrapper = extendedWrapper(
      shallowMount(ReportsModal, {
        propsData: {
          title,
          modalData: modalDataStructure,
          visible: true,
        },
        stubs: { GlModal: StubbedGlModal, GlSprintf },
      }),
    );
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders code block', () => {
    expect(wrapper.find(CodeBlock).props().code).toEqual(modalDataStructure.system_output.value);
  });

  it('renders link', () => {
    const link = wrapper.findComponent(GlLink);

    expect(link.attributes().href).toEqual(modalDataStructure.filename.value.path);

    expect(link.text()).toEqual(modalDataStructure.filename.value.text);
  });

  it('renders seconds', () => {
    expect(wrapper.text()).toContain(`${modalDataStructure.execution_time.value} s`);
  });

  it('render title', () => {
    expect(wrapper.findComponent(StubbedGlModal).props().title).toEqual(title);
  });

  it('re-emits hide event', () => {
    wrapper.findComponent(StubbedGlModal).vm.$emit('hide');
    expect(wrapper.emitted().hide).toEqual([[]]);
  });
});
