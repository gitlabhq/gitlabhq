import { shallowMount, mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import { EVT_EXPAND_ALL_FILES } from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';
import createStore from '~/diffs/store/modules';

import { getDiffFileMock } from '../mock_data/diff_file';

const propsData = {
  limited: true,
  mergeable: true,
  resolutionPath: 'a-path',
};

async function files(store, count) {
  const copies = Array(count).fill(getDiffFileMock());
  store.state.diffs.diffFiles.push(...copies);

  await nextTick();
}

describe('CollapsedFilesWarning', () => {
  let store;
  let wrapper;

  Vue.use(Vuex);

  const getAlertActionButton = () =>
    wrapper.findComponent(CollapsedFilesWarning).find('button.gl-alert-action:first-child');
  const getAlertCloseButton = () => wrapper.findComponent(CollapsedFilesWarning).find('button');

  const createComponent = (props = {}, { full } = { full: false }) => {
    const mounter = full ? mount : shallowMount;
    store = new Vuex.Store({
      modules: {
        diffs: createStore(),
      },
    });

    wrapper = mounter(CollapsedFilesWarning, {
      propsData: { ...propsData, ...props },
      store,
    });
  };

  describe('when there is more than one file', () => {
    it.each`
      present  | dismissed
      ${false} | ${true}
      ${true}  | ${false}
    `('toggles the alert when dismissed is $dismissed', async ({ present, dismissed }) => {
      createComponent({ dismissed });
      await files(store, 2);

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(present);
    });

    it('dismisses the component when the alert "x" is clicked', async () => {
      createComponent({}, { full: true });
      await files(store, 2);

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(true);

      getAlertCloseButton().element.click();

      await nextTick();

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(false);
    });

    it(`emits the \`${EVT_EXPAND_ALL_FILES}\` event when the alert action button is clicked`, async () => {
      createComponent({}, { full: true });
      await files(store, 2);

      jest.spyOn(eventHub, '$emit');

      getAlertActionButton().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(EVT_EXPAND_ALL_FILES);
    });
  });

  describe('when there is a single file', () => {
    it('should not display', async () => {
      createComponent();
      await files(store, 1);

      expect(wrapper.find('[data-testid="root"]').exists()).toBe(false);
    });
  });
});
