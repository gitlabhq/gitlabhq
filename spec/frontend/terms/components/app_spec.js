import { merge } from 'lodash';
import { GlIntersectionObserver } from '@gitlab/ui';
import { nextTick } from 'vue';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import TermsApp from '~/terms/components/app.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));
jest.mock('~/lib/utils/common_utils');
jest.mock('~/behaviors/markdown/render_gfm');

describe('TermsApp', () => {
  let wrapper;

  const defaultProvide = {
    terms: 'foo bar',
    paths: {
      accept: '/-/users/terms/1/accept',
      decline: '/-/users/terms/1/decline',
      root: '/',
    },
    permissions: {
      canAccept: true,
      canDecline: true,
    },
  };

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(TermsApp, {
      provide: merge({}, defaultProvide, provide),
    });
  };

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
  });

  const findFormWithAction = (path) => wrapper.find(`form[action="${path}"]`);
  const findButton = (path) => findFormWithAction(path).find('button[type="submit"]');
  const findScrollableViewport = () => wrapper.findByTestId('scrollable-viewport');

  const expectFormWithSubmitButton = (buttonText, path) => {
    const form = findFormWithAction(path);
    const submitButton = findButton(path);

    expect(form.exists()).toBe(true);
    expect(submitButton.exists()).toBe(true);
    expect(submitButton.text()).toBe(buttonText);
    expect(
      form
        .find('input[type="hidden"][name="authenticity_token"][value="mock-csrf-token"]')
        .exists(),
    ).toBe(true);
  };

  it('renders terms of service as markdown', () => {
    createComponent();

    expect(wrapper.findByText(defaultProvide.terms).exists()).toBe(true);
    expect(renderGFM).toHaveBeenCalled();
  });

  describe('accept button', () => {
    it('is disabled until user scrolls to the bottom of the terms', async () => {
      createComponent();
      expect(findButton(defaultProvide.paths.accept).attributes('disabled')).toBe('disabled');

      wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');

      await nextTick();

      expect(findButton(defaultProvide.paths.accept).attributes('disabled')).toBeUndefined();
    });

    describe('when user has permissions to accept', () => {
      it('renders form and button to accept terms', () => {
        createComponent();

        expectFormWithSubmitButton(TermsApp.i18n.accept, defaultProvide.paths.accept);
      });
    });

    describe('when user does not have permissions to accept', () => {
      it('renders continue button', () => {
        createComponent({ permissions: { canAccept: false } });

        expect(wrapper.findByText(TermsApp.i18n.continue).exists()).toBe(true);
      });
    });
  });

  describe('decline button', () => {
    describe('when user has permissions to decline', () => {
      it('renders form and button to decline terms', () => {
        createComponent();

        expectFormWithSubmitButton(TermsApp.i18n.decline, defaultProvide.paths.decline);
      });
    });

    describe('when user does not have permissions to decline', () => {
      it('does not render decline button', () => {
        createComponent({ permissions: { canDecline: false } });

        expect(wrapper.findByText(TermsApp.i18n.decline).exists()).toBe(false);
      });
    });
  });

  it('sets height of scrollable viewport', () => {
    jest.spyOn(document.documentElement, 'scrollHeight', 'get').mockImplementation(() => 800);
    jest.spyOn(document.documentElement, 'clientHeight', 'get').mockImplementation(() => 600);

    createComponent();

    expect(findScrollableViewport().attributes('style')).toBe('max-height: calc(100vh - 200px);');
  });

  describe('when flash is closed', () => {
    let flashEl;

    beforeEach(() => {
      flashEl = document.createElement('div');
      document.body.appendChild(flashEl);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('recalculates height of scrollable viewport', async () => {
      jest.spyOn(document.documentElement, 'scrollHeight', 'get').mockImplementation(() => 800);
      jest.spyOn(document.documentElement, 'clientHeight', 'get').mockImplementation(() => 600);

      createComponent();

      expect(findScrollableViewport().attributes('style')).toBe('max-height: calc(100vh - 200px);');

      jest.spyOn(document.documentElement, 'scrollHeight', 'get').mockImplementation(() => 700);
      jest.spyOn(document.documentElement, 'clientHeight', 'get').mockImplementation(() => 600);

      flashEl.remove();
      await nextTick();

      expect(findScrollableViewport().attributes('style')).toBe('max-height: calc(100vh - 100px);');
    });
  });

  describe('when user is signed out', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(false);
    });

    it('does not show any buttons', () => {
      createComponent();

      expect(wrapper.findByText(TermsApp.i18n.accept).exists()).toBe(false);
      expect(wrapper.findByText(TermsApp.i18n.decline).exists()).toBe(false);
      expect(wrapper.findByText(TermsApp.i18n.continue).exists()).toBe(false);
    });
  });
});
