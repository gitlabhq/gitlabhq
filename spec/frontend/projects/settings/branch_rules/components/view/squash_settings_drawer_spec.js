import { nextTick } from 'vue';
import { GlDrawer, GlFormRadioGroup, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import SquashSettingsDrawer from '~/projects/settings/branch_rules/components/view/squash_settings_drawer.vue';

jest.mock('~/lib/utils/dom_utils', () => ({ getContentWrapperHeight: jest.fn() }));

describe('Squash Settings Drawer', () => {
  let wrapper;
  const TEST_HEADER_HEIGHT = '123px';

  const defaultProps = {
    isOpen: false,
    isLoading: false,
    selectedOption: 'do_not_allow',
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findSaveButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findCancelButton = () => wrapper.findAllComponents(GlButton).at(1);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SquashSettingsDrawer, {
      propsData: { ...defaultProps, ...props },
    });
  };

  beforeEach(() => {
    getContentWrapperHeight.mockReturnValue(TEST_HEADER_HEIGHT);
    createComponent();
  });

  describe('content', () => {
    it('renders drawer with correct props', () => {
      expect(findDrawer().props()).toMatchObject({
        open: false,
        headerHeight: TEST_HEADER_HEIGHT,
        zIndex: DRAWER_Z_INDEX,
      });
    });

    it.each(['Do not allow', 'Allow', 'Encourage', 'Require'])(
      'renders radio option for %s',
      (label) => {
        expect(wrapper.text()).toContain(label);
      },
    );

    it.each([
      ['encourage', 'encourage'],
      [undefined, 'do_not_allow'],
    ])('sets correct initial selection for %s', async (input, expected) => {
      createComponent({ selectedOption: input });
      await nextTick();
      findSaveButton().vm.$emit('click');
      expect(wrapper.emitted('submit')).toContainEqual([expected]);
    });
  });

  describe('interactions', () => {
    describe('save button', () => {
      it('emits submit event with selected value', async () => {
        findRadioGroup().vm.$emit('input', 'allow');
        await nextTick();

        findSaveButton().vm.$emit('click');

        expect(wrapper.emitted('submit')).toHaveLength(1);
        expect(wrapper.emitted('submit')).toContainEqual(['allow']);
      });

      it('is disabled when no changes are made', () => {
        expect(findSaveButton().props('disabled')).toBe(true);
      });

      it('is enabled after selection changes', async () => {
        findRadioGroup().vm.$emit('input', 'allow');
        await nextTick();

        expect(findSaveButton().props('disabled')).toBe(false);
      });

      it('shows loading state when isLoading is true', () => {
        createComponent({ isLoading: true });
        expect(findSaveButton().props('loading')).toBe(true);
      });
    });

    describe('cancel button', () => {
      it('emits close event when clicked', () => {
        findCancelButton().vm.$emit('click');
        expect(wrapper.emitted('close')).toHaveLength(1);
      });
    });
  });
});
