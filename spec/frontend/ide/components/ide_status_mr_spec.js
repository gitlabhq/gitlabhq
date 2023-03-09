import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import IdeStatusMr from '~/ide/components/ide_status_mr.vue';

const TEST_TEXT = '!9001';
const TEST_URL = `${TEST_HOST}merge-requests/9001`;

describe('ide/components/ide_status_mr', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(IdeStatusMr, {
      propsData: props,
    });
  };
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent({
        text: TEST_TEXT,
        url: TEST_URL,
      });
    });

    it('renders icon', () => {
      const icon = findIcon();

      expect(icon.exists()).toBe(true);
      expect(icon.props()).toEqual(
        expect.objectContaining({
          name: 'merge-request',
        }),
      );
    });

    it('renders link', () => {
      const link = findLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes()).toEqual(
        expect.objectContaining({
          href: TEST_URL,
        }),
      );
      expect(link.text()).toEqual(TEST_TEXT);
    });

    it('renders text', () => {
      expect(wrapper.text()).toBe(`Merge request ${TEST_TEXT}`);
    });
  });
});
