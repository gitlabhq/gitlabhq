import SafeLink from 'ee/vue_shared/components/safe_link.vue';
import { mountComponentWithSlots } from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import Vue from 'vue';

describe('SafeLink', () => {
  const Component = Vue.extend(SafeLink);
  const httpLink = `${TEST_HOST}/safe_link.html`;
  // eslint-disable-next-line no-script-url
  const javascriptLink = 'javascript:alert("jay")';
  const linkText = 'Link Text';

  const linkProps = {
    hreflang: 'XR',
    rel: 'alternate',
    type: 'text/html',
    target: '_blank',
    media: 'all',
  };

  let vm;

  describe('valid link', () => {
    let props;

    beforeEach(() => {
      props = { href: httpLink, ...linkProps };
      vm = mountComponentWithSlots(Component, { props, slots: { default: [linkText] } });
    });

    it('renders a link element', () => {
      expect(vm.$el.tagName).toEqual('A');
    });

    it('renders link specific attributes', () => {
      expect(vm.$el.getAttribute('href')).toEqual(httpLink);
      Object.keys(linkProps).forEach(key => {
        expect(vm.$el.getAttribute(key)).toEqual(linkProps[key]);
      });
    });

    it('renders the inner text as provided', () => {
      expect(vm.$el.innerText).toEqual(linkText);
    });
  });

  describe('invalid link', () => {
    let props;

    beforeEach(() => {
      props = { href: javascriptLink, ...linkProps };
      vm = mountComponentWithSlots(Component, { props, slots: { default: [linkText] } });
    });

    it('renders a span element', () => {
      expect(vm.$el.tagName).toEqual('SPAN');
    });

    it('renders without link specific attributes', () => {
      expect(vm.$el.getAttribute('href')).toEqual(null);
      Object.keys(linkProps).forEach(key => {
        expect(vm.$el.getAttribute(key)).toEqual(null);
      });
    });

    it('renders the inner text as provided', () => {
      expect(vm.$el.innerText).toEqual(linkText);
    });
  });
});
