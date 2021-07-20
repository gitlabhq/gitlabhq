import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import { CENTERED_LIMITED_CONTAINER_CLASSES, EVT_EXPAND_ALL_FILES } from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';
import createStore from '~/diffs/store/modules';

import file from '../mock_data/diff_file';

const propsData = {
  limited: true,
  mergeable: true,
  resolutionPath: 'a-path',
};
const limitedClasses = CENTERED_LIMITED_CONTAINER_CLASSES.split(' ');

async function files(store, count) {
  const copies = Array(count).fill(file);
  store.state.diffs.diffFiles.push(...copies);

  return nextTick();
}

describe('CollapsedFilesWarning', () => {
  const localVue = createLocalVue();
  let store;
  let wrapper;

  localVue.use(Vuex);

  const getAlertActionButton = () =>
    wrapper.find(CollapsedFilesWarning).find('button.gl-alert-action:first-child');
  const getAlertCloseButton = () => wrapper.find(CollapsedFilesWarning).find('button');

  const createComponent = (props = {}, { full } = { full: false }) => {
    const mounter = full ? mount : shallowMount;
    store = new Vuex.Store({
      modules: {
        diffs: createStore(),
      },
    });

    wrapper = mounter(CollapsedFilesWarning, {
      propsData: { ...propsData, ...props },
      localVue,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there is more than one file', () => {
    it.each`
      limited  | containerClasses
      ${true}  | ${limitedClasses}
      ${false} | ${[]}
    `(
      'has the correct container classes when limited is $limited',
      async ({ limited, containerClasses }) => {
        createComponent({ limited });
        await files(store, 2);

        expect(wrapper.classes()).toEqual(['col-12'].concat(containerClasses));
      },
    );

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

      await wrapper.vm.$nextTick();

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
