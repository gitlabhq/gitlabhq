import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DropdownFooter from '~/sidebar/components/labels/labels_select_widget/dropdown_footer.vue';

describe('DropdownFooter', () => {
  let wrapper;

  const createComponent = ({ props = {}, injected = {} } = {}) => {
    wrapper = shallowMountExtended(DropdownFooter, {
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

  const findCreateLabelButton = () => wrapper.findByTestId('create-label-button');
  const findManageLabelsButton = () => wrapper.findByTestId('manage-labels-button');

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

      it('emits `toggleDropdownContentsCreateView` event on create label button click', () => {
        findCreateLabelButton().trigger('click');

        expect(wrapper.emitted('toggleDropdownContentsCreateView')).toEqual([[]]);
      });
    });

    describe('manage labels button', () => {
      it('is rendered', () => {
        expect(findManageLabelsButton().exists()).toBe(true);
      });

      describe('when footerManageLabelTitle is not given', () => {
        beforeEach(() => {
          createComponent({ props: { footerManageLabelTitle: undefined } });
        });

        it('does not render manage labels button', () => {
          expect(findManageLabelsButton().exists()).toBe(false);
        });
      });

      describe('when labelsManagePath is not provided', () => {
        beforeEach(() => {
          createComponent({ injected: { labelsManagePath: '' } });
        });

        it('does not render manage labels button', () => {
          expect(findManageLabelsButton().exists()).toBe(false);
        });
      });
    });
  });
});
