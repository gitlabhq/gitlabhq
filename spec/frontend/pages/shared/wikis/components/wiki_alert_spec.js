import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WikiAlert from '~/pages/shared/wikis/components/wiki_alert.vue';

describe('WikiAlert', () => {
  let wrapper;
  const ERROR = 'There is already a page with the same title in that path.';
  const ERROR_WITH_LINK = 'Before text %{wikiLinkStart}the page%{wikiLinkEnd} after text.';
  const PATH = '/test';

  function createWrapper(propsData = {}, stubs = {}) {
    wrapper = shallowMount(WikiAlert, {
      propsData: { wikiPagePath: PATH, ...propsData },
      stubs,
    });
  }

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findGlSprintf = () => wrapper.findComponent(GlSprintf);

  describe('Wiki Alert', () => {
    it('shows an alert when there is an error', () => {
      createWrapper({ error: ERROR });
      expect(findGlAlert().exists()).toBe(true);
      expect(findGlSprintf().exists()).toBe(true);
      expect(findGlSprintf().attributes('message')).toBe(ERROR);
    });

    it('shows a the link to the help path', () => {
      createWrapper({ error: ERROR_WITH_LINK }, { GlAlert, GlSprintf });
      expect(findGlLink().attributes('href')).toBe(PATH);
    });
  });
});
