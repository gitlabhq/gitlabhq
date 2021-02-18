import { GlDrawer } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import EditDrawer from '~/static_site_editor/components/edit_drawer.vue';
import FrontMatterControls from '~/static_site_editor/components/front_matter_controls.vue';

describe('~/static_site_editor/components/edit_drawer.vue', () => {
  let wrapper;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(EditDrawer, {
      propsData: {
        isOpen: false,
        settings: { title: 'Some title' },
        ...propsData,
      },
    });
  };

  const findFrontMatterControls = () => wrapper.find(FrontMatterControls);
  const findGlDrawer = () => wrapper.find(GlDrawer);

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the GlDrawer', () => {
    expect(findGlDrawer().exists()).toBe(true);
  });

  it('renders the FrontMatterControls', () => {
    expect(findFrontMatterControls().exists()).toBe(true);
  });

  it('forwards the settings to FrontMatterControls', () => {
    expect(findFrontMatterControls().props('settings')).toBe(wrapper.props('settings'));
  });

  it('is closed by default', () => {
    expect(findGlDrawer().props('open')).toBe(false);
  });

  it('can open', () => {
    buildWrapper({ isOpen: true });

    expect(findGlDrawer().props('open')).toBe(true);
  });

  it.each`
    event               | payload             | finderFn
    ${'close'}          | ${undefined}        | ${findGlDrawer}
    ${'updateSettings'} | ${{ some: 'data' }} | ${findFrontMatterControls}
  `(
    'forwards the emitted $event event from the $finderFn with $payload',
    ({ event, payload, finderFn }) => {
      finderFn().vm.$emit(event, payload);

      expect(wrapper.emitted(event)[0][0]).toBe(payload);
      expect(wrapper.emitted(event).length).toBe(1);
    },
  );
});
