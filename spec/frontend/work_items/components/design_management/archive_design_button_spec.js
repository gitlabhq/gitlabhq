import { nextTick } from 'vue';
import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ArchiveDesignButton from '~/work_items/components/design_management/archive_design_button.vue';

const modalTitle = 'Are you sure you want to archive the selected designs?';
const modalText =
  'Archived designs will still be available in previous versions of the design collection.';

describe('ArchiveDesignButton', () => {
  let wrapper;

  const findArchiveDesignButton = () => wrapper.findByTestId('archive-design-button');
  const findArchiveModal = () => wrapper.findComponent(GlModal);

  function createComponent({ hasSelectedDesigns = false } = {}) {
    wrapper = shallowMountExtended(ArchiveDesignButton, {
      propsData: {
        hasSelectedDesigns,
      },
    });
  }

  it('renders disabled button when no selected designs provided', () => {
    createComponent();

    expect(findArchiveDesignButton().exists()).toBe(true);
    expect(findArchiveDesignButton().props('disabled')).toBe(true);
  });

  it('renders modal and archives designs if designs are selected', async () => {
    createComponent({ hasSelectedDesigns: true });

    expect(findArchiveDesignButton().props('disabled')).toBe(false);

    findArchiveDesignButton().trigger('click');
    await nextTick();

    expect(findArchiveModal().exists()).toBe(true);
    expect(findArchiveModal().props().title).toBe(modalTitle);
    expect(findArchiveModal().text()).toContain(modalText);

    findArchiveModal().vm.$emit('ok');
    expect(wrapper.emitted('archive-selected-designs')).toEqual([[]]);
  });
});
