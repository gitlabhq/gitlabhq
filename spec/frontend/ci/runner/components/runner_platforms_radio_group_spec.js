import { nextTick } from 'vue';
import { GlFormRadioGroup, GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerPlatformsRadio from '~/ci/runner/components/runner_platforms_radio.vue';

import {
  LINUX_PLATFORM,
  MACOS_PLATFORM,
  WINDOWS_PLATFORM,
  DOCKER_HELP_URL,
  KUBERNETES_HELP_URL,
} from '~/ci/runner/constants';

import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';

describe('RunnerPlatformsRadioGroup', () => {
  let wrapper;

  const findFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findFormRadios = () => wrapper.findAllComponents(RunnerPlatformsRadio).wrappers;
  const findFormRadioByText = (text) =>
    findFormRadios()
      .filter((w) => w.text() === text)
      .at(0);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerPlatformsRadioGroup, {
      propsData: {
        value: null,
        ...props,
      },
      ...options,
    });
  };

  describe('defaults', () => {
    beforeEach(() => {
      createComponent();
    });

    it('contains expected options with images', () => {
      const labels = findFormRadios().map((w) => [w.text(), w.props('image')]);

      expect(labels).toStrictEqual([
        ['Linux', expect.any(String)],
        ['macOS', null],
        ['Windows', null],
        ['Docker', expect.any(String)],
        ['Kubernetes', expect.any(String)],
      ]);
    });

    it('allows users to use radio group', async () => {
      findFormRadioGroup().vm.$emit('input', MACOS_PLATFORM);
      await nextTick();

      expect(wrapper.emitted('input')[0]).toEqual([MACOS_PLATFORM]);
    });

    it.each`
      text         | value
      ${'Linux'}   | ${LINUX_PLATFORM}
      ${'macOS'}   | ${MACOS_PLATFORM}
      ${'Windows'} | ${WINDOWS_PLATFORM}
    `('user can select "$text"', async ({ text, value }) => {
      const radio = findFormRadioByText(text);
      expect(radio.props('value')).toBe(value);

      radio.vm.$emit('input', value);
      await nextTick();

      expect(wrapper.emitted('input')[0]).toEqual([value]);
    });

    it.each`
      text            | href
      ${'Docker'}     | ${DOCKER_HELP_URL}
      ${'Kubernetes'} | ${KUBERNETES_HELP_URL}
    `('provides link to "$text" docs', ({ text, href }) => {
      const radio = findFormRadioByText(text);

      expect(radio.findComponent(GlLink).attributes()).toEqual({
        href,
        target: '_blank',
      });
      expect(radio.findComponent(GlIcon).props('name')).toBe('external-link');
    });

    it('contains google cloud platform option', () => {
      createComponent({
        props: {},
        mountFn: shallowMountExtended,
        slots: {
          'cloud-options': 'Google cloud',
        },
      });

      expect(findFormRadioGroup().text()).toContain('Google cloud');
    });
  });
});
