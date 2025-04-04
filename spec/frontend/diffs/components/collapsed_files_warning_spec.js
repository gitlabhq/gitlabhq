import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import { EVT_EXPAND_ALL_FILES } from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { getDiffFileMock } from '../mock_data/diff_file';

const propsData = {
  limited: true,
  mergeable: true,
  resolutionPath: 'a-path',
};

Vue.use(PiniaVuePlugin);

describe('CollapsedFilesWarning', () => {
  let wrapper;
  let pinia;

  const getAlertActionButton = () =>
    wrapper.findComponent(CollapsedFilesWarning).find('button.gl-alert-action:first-child');
  const getAlertCloseButton = () => wrapper.findComponent(CollapsedFilesWarning).find('button');

  const createComponent = (props = {}, { full } = { full: false }) => {
    const mounter = full ? mount : shallowMount;
    wrapper = mounter(CollapsedFilesWarning, {
      propsData: { ...propsData, ...props },
      pinia,
    });
  };

  async function files(count) {
    const copies = Array(count).fill(getDiffFileMock());
    useLegacyDiffs().diffFiles.push(...copies);
    await nextTick();
  }

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
  });

  describe('when there is more than one file', () => {
    it.each`
      present  | dismissed
      ${false} | ${true}
      ${true}  | ${false}
    `('toggles the alert when dismissed is $dismissed', async ({ present, dismissed }) => {
      createComponent({ dismissed });
      await files(2);

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(present);
    });

    it('dismisses the component when the alert "x" is clicked', async () => {
      createComponent({}, { full: true });
      await files(2);

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(true);

      getAlertCloseButton().element.click();

      await nextTick();

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(false);
    });

    it(`emits the \`${EVT_EXPAND_ALL_FILES}\` event when the alert action button is clicked`, async () => {
      createComponent({}, { full: true });
      await files(2);

      jest.spyOn(eventHub, '$emit');

      getAlertActionButton().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(EVT_EXPAND_ALL_FILES);
    });
  });

  describe('when there is a single file', () => {
    it('should not display', async () => {
      createComponent();
      await files(1);

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(false);
    });
  });
});
