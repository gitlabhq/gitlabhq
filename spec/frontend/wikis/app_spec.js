import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import WikiApp from '~/wikis/app.vue';
import WikiAlert from '~/wikis/components/wiki_alert.vue';
import WikiHeader from '~/wikis/components/wiki_header.vue';
import WikiContent from '~/wikis/components/wiki_content.vue';
import WikiEditForm from '~/wikis/components/wiki_form.vue';
import WikiNotesApp from '~/wikis/wiki_notes/components/wiki_notes_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('WikiApp', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(WikiApp, {
      provide: {
        wikiUrl: 'foo/bar',
        historyUrl: 'foo/history',
        ...provide,
      },
    });
  };

  describe('with default settings', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders without error', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('does not show any alert', () => {
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
      expect(wrapper.findComponent(WikiAlert).exists()).toBe(false);
    });

    it('does show the wiki header', () => {
      expect(wrapper.findComponent(WikiHeader).exists()).toBe(true);
    });

    it('does show the wiki content', () => {
      expect(wrapper.findComponent(WikiContent).exists()).toBe(true);
    });

    it('does not show the wiki edit form', () => {
      expect(wrapper.findComponent(WikiEditForm).exists()).toBe(false);
    });

    it('does show the wiki notes', () => {
      expect(wrapper.findComponent(WikiNotesApp).exists()).toBe(true);
    });

    it(`toggles editing state`, async () => {
      expect(wrapper.findComponent(WikiContent).exists()).toBe(true);
      expect(wrapper.findComponent(WikiEditForm).exists()).toBe(false);

      wrapper.getComponent(WikiHeader).vm.$emit('is-editing', true);
      await nextTick();

      expect(wrapper.findComponent(WikiContent).exists()).toBe(false);
      expect(wrapper.findComponent(WikiEditForm).exists()).toBe(true);

      wrapper.getComponent(WikiEditForm).vm.$emit('is-editing', false);
      await nextTick();

      expect(wrapper.findComponent(WikiContent).exists()).toBe(true);
      expect(wrapper.findComponent(WikiEditForm).exists()).toBe(false);
    });
  });

  describe('when editing', () => {
    beforeEach(() => {
      createComponent({ isEditingPath: true });
    });

    it('does not show the wiki content', () => {
      expect(wrapper.findComponent(WikiContent).exists()).toBe(false);
    });

    it('does show the wiki edit form', () => {
      expect(wrapper.findComponent(WikiEditForm).exists()).toBe(true);
    });

    it('does not show the wiki notes', () => {
      expect(wrapper.findComponent(WikiNotesApp).exists()).toBe(false);
    });
  });

  describe('when editing a saved wiki page', () => {
    beforeEach(() => {
      createComponent({ isEditingPath: true, pagePersisted: true });
    });

    it('does show the wiki notes', () => {
      expect(wrapper.findComponent(WikiNotesApp).exists()).toBe(true);
    });
  });

  describe('when viewing a historical page', () => {
    beforeEach(() => {
      createComponent({ isPageHistorical: true });
    });

    it('does show a notification', () => {
      const alert = wrapper.getComponent(GlAlert);
      expect(alert.text()).toContain('This is an old version of this page.');
      expect(alert.props('primaryButtonText')).toBe('Go to most recent version');
      expect(alert.props('primaryButtonLink')).toBe('foo/bar');
      expect(alert.props('secondaryButtonText')).toBe('Browse history');
      expect(alert.props('secondaryButtonLink')).toBe('foo/history');
    });
  });

  describe('when the page has an error', () => {
    beforeEach(() => {
      createComponent({
        error: 'Some Error',
      });
    });

    it('does show a notification', () => {
      const alert = wrapper.getComponent(WikiAlert);
      expect(alert.props('error')).toBe('Some Error');
      expect(alert.props('wikiPagePath')).toBe('foo/bar');
    });
  });
});
