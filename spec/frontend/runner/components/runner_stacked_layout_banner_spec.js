import { nextTick } from 'vue';
import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerStackedLayoutBanner from '~/runner/components/runner_stacked_layout_banner.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('RunnerStackedLayoutBanner', () => {
  let wrapper;

  const findBanner = () => wrapper.findComponent(GlBanner);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const createComponent = ({ ...options } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(RunnerStackedLayoutBanner, {
      ...options,
    });
  };

  it('Displays a banner', () => {
    createComponent();

    expect(findBanner().props()).toMatchObject({
      svgPath: expect.stringContaining('data:image/svg+xml;utf8,'),
      title: expect.any(String),
      buttonText: expect.any(String),
      buttonLink: expect.stringContaining('https://gitlab.com/gitlab-org/gitlab/-/issues/'),
    });
    expect(findLocalStorageSync().exists()).toBe(true);
  });

  it('Does not display a banner when dismissed', async () => {
    findLocalStorageSync().vm.$emit('input', true);

    await nextTick();

    expect(findBanner().exists()).toBe(false);
    expect(findLocalStorageSync().exists()).toBe(true); // continues syncing after removal
  });
});
