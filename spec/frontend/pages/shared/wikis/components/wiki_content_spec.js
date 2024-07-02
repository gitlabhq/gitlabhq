import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import WikiContent from '~/pages/shared/wikis/components/wiki_content.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { handleLocationHash } from '~/lib/utils/common_utils';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/lib/utils/common_utils');

describe('pages/shared/wikis/components/wiki_content', () => {
  const PATH = '/test';
  let wrapper;
  let mock;

  function buildWrapper(propsData = {}) {
    wrapper = shallowMount(WikiContent, {
      provide: {
        contentApi: PATH,
      },
      propsData: { ...propsData },
      stubs: {
        GlSkeletonLoader,
        GlAlert,
      },
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findContent = () => wrapper.find('[data-testid="wiki-page-content"]');

  describe('when loading content', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders skeleton loader', () => {
      expect(findGlSkeletonLoader().exists()).toBe(true);
    });

    it('does not render content container or error alert', () => {
      expect(findGlAlert().exists()).toBe(false);
      expect(findContent().exists()).toBe(false);
    });
  });

  describe('when content loads successfully', () => {
    const content = 'content';

    beforeEach(() => {
      mock.onGet(PATH, { params: { render_html: true } }).replyOnce(HTTP_STATUS_OK, { content });
      buildWrapper();
      return waitForPromises();
    });

    it('renders content container', () => {
      expect(findContent().text()).toBe(content);
    });

    it('does not render skeleton loader or error alert', () => {
      expect(findGlAlert().exists()).toBe(false);
      expect(findGlSkeletonLoader().exists()).toBe(false);
    });

    it('calls renderGFM after nextTick', async () => {
      await nextTick();

      expect(renderGFM).toHaveBeenCalled();
    });

    it('handles hash after render', async () => {
      await nextTick();

      expect(handleLocationHash).toHaveBeenCalled();
    });
  });

  describe('when loading content fails', () => {
    beforeEach(() => {
      mock.onGet(PATH).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, '');
      buildWrapper();
      return waitForPromises();
    });

    it('renders error alert', () => {
      expect(findGlAlert().exists()).toBe(true);
    });

    it('does not render skeleton loader or content container', () => {
      expect(findContent().exists()).toBe(false);
      expect(findGlSkeletonLoader().exists()).toBe(false);
    });
  });
});
