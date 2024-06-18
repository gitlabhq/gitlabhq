import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import PublishMessage from '~/packages_and_registries/shared/components/publish_message.vue';
import { useFakeDate } from 'helpers/fake_date';

describe('PublishMessage', () => {
  let wrapper;

  // set the date to June 4, 2020
  useFakeDate(2020, 6, 4);

  const defaultProps = { publishDate: '2020-05-17T14:23:32Z' };

  const findProjectLink = () => wrapper.findComponent(GlLink);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PublishMessage, {
      stubs: {
        GlSprintf,
        TimeAgoTooltip,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  it.each`
    additionalProps                                                                          | expectedText                                            | expectedHref
    ${{}}                                                                                    | ${'Published 1 month ago'}                              | ${undefined}
    ${{ author: 'Administrator' }}                                                           | ${'Published by Administrator, 1 month ago'}            | ${undefined}
    ${{ projectName: 'example' }}                                                            | ${'Published to example, 1 month ago'}                  | ${'#'}
    ${{ projectName: 'example', projectUrl: 'http://example.com' }}                          | ${'Published to example, 1 month ago'}                  | ${'http://example.com'}
    ${{ projectName: 'example', author: 'Administrator' }}                                   | ${'Published to example by Administrator, 1 month ago'} | ${'#'}
    ${{ projectName: 'example', projectUrl: 'http://example.com', author: 'Administrator' }} | ${'Published to example by Administrator, 1 month ago'} | ${'http://example.com'}
  `(
    'renders $expectedText with $additionalProps',
    ({ additionalProps, expectedText, expectedHref }) => {
      createComponent(additionalProps);

      expect(wrapper.text()).toBe(expectedText);
      if (expectedHref) {
        expect(findProjectLink().attributes('href')).toBe(expectedHref);
      }
    },
  );
});
