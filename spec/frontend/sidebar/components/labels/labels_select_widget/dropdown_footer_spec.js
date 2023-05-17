import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DropdownFooter from '~/sidebar/components/labels/labels_select_widget/dropdown_footer.vue';

describe('DropdownFooter', () => {
  let wrapper;

  const createComponent = ({ props = {}, injected = {} } = {}) => {
    wrapper = shallowMount(DropdownFooter, {
      propsData: {
        footerCreateLabelTitle: 'create',
        footerManageLabelTitle: 'manage',
        ...props,
      },
      provide: {
        allowLabelCreate: true,
        labelsManagePath: 'foo/bar',
        ...injected,
      },
    });
  };

  const findCreateLabelButton = () => wrapper.find('[data-testid="create-label-button"]');

  describe('Labels view', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render create label button if `allowLabelCreate` is false', () => {
      createComponent({ injected: { allowLabelCreate: false } });

      expect(findCreateLabelButton().exists()).toBe(false);
    });

    describe('when `allowLabelCreate` is true', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders create label button', () => {
        expect(findCreateLabelButton().exists()).toBe(true);
      });

      it('emits `toggleDropdownContentsCreateView` event on create label button click', async () => {
        findCreateLabelButton().trigger('click');

        await nextTick();
        expect(wrapper.emitted('toggleDropdownContentsCreateView')).toEqual([[]]);
      });
    });
  });
});
