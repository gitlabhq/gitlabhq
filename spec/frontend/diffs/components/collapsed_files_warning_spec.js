import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import { CENTERED_LIMITED_CONTAINER_CLASSES, EVT_EXPAND_ALL_FILES } from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';
import createStore from '~/diffs/store/modules';

const propsData = {
  limited: true,
  mergeable: true,
  resolutionPath: 'a-path',
};
const limitedClasses = CENTERED_LIMITED_CONTAINER_CLASSES.split(' ');

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

  it.each`
    limited  | containerClasses
    ${true}  | ${limitedClasses}
    ${false} | ${[]}
  `(
    'has the correct container classes when limited is $limited',
    ({ limited, containerClasses }) => {
      createComponent({ limited });

      expect(wrapper.classes()).toEqual(['col-12'].concat(containerClasses));
    },
  );

  it.each`
    present  | dismissed
    ${false} | ${true}
    ${true}  | ${false}
  `('toggles the alert when dismissed is $dismissed', ({ present, dismissed }) => {
    createComponent({ dismissed });

    expect(wrapper.find('[data-testid="root"]').exists()).toBe(present);
  });

  it('dismisses the component when the alert "x" is clicked', async () => {
    createComponent({}, { full: true });

    expect(wrapper.find('[data-testid="root"]').exists()).toBe(true);

    getAlertCloseButton().element.click();

    await wrapper.vm.$nextTick();

    expect(wrapper.find('[data-testid="root"]').exists()).toBe(false);
  });

  it(`emits the \`${EVT_EXPAND_ALL_FILES}\` event when the alert action button is clicked`, () => {
    createComponent({}, { full: true });

    jest.spyOn(eventHub, '$emit');

    getAlertActionButton().vm.$emit('click');

    expect(eventHub.$emit).toHaveBeenCalledWith(EVT_EXPAND_ALL_FILES);
  });
});
