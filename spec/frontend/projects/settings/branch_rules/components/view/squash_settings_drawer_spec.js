import { nextTick } from 'vue';
import { GlDrawer, GlFormRadioGroup, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import SquashSettingsDrawer from '~/projects/settings/branch_rules/components/view/squash_settings_drawer.vue';
import {
  SQUASH_SETTING_DEFAULT,
  SQUASH_SETTING_DO_NOT_ALLOW,
  SQUASH_SETTING_ALLOW,
  SQUASH_SETTING_ENCOURAGE,
  SQUASH_SETTING_REQUIRE,
} from '~/projects/settings/branch_rules/components/view/constants';

jest.mock('~/lib/utils/dom_utils', () => ({ getContentWrapperHeight: jest.fn() }));

describe('Squash Settings Drawer', () => {
  let wrapper;
  const TEST_HEADER_HEIGHT = '123px';

  const defaultProps = {
    isOpen: false,
    isLoading: false,
    selectedOption: SQUASH_SETTING_DO_NOT_ALLOW,
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
      ['Default', SQUASH_SETTING_DEFAULT],
      ['Allow', SQUASH_SETTING_ALLOW],
      ['Encourage', SQUASH_SETTING_ENCOURAGE],
      ['Require', SQUASH_SETTING_REQUIRE],
      ['Do not allow', SQUASH_SETTING_DO_NOT_ALLOW],
    ])('sets correct selection for %s', async (input, expected) => {
      createComponent({ selectedOption: input });
      await nextTick();
      findSaveButton().vm.$emit('click');
      expect(wrapper.emitted('submit')).toContainEqual([expected]);
    });

    it('sets correct selection for Default option when isAllBranchesRule is true', async () => {
      createComponent({ selectedOption: undefined, isAllBranchesRule: true });
      await nextTick();
      findSaveButton().vm.$emit('click');
      expect(wrapper.emitted('submit')).toContainEqual([SQUASH_SETTING_DO_NOT_ALLOW]);
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

      it('is enabled when selectedOption is null', async () => {
        createComponent({ selectedOption: null });
        await nextTick();

        expect(findSaveButton().props('disabled')).toBe(false);
      });

      it('is enabled when selection differs from selectedOption', async () => {
        createComponent({ selectedOption: SQUASH_SETTING_ALLOW });
        findRadioGroup().vm.$emit('input', SQUASH_SETTING_ENCOURAGE);
        await nextTick();

        expect(findSaveButton().props('disabled')).toBe(false);
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
