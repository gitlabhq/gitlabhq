<script>
import isSafeURL from './is_safe_url';
/**
 * Renders a link element (`<a>`) if the href is a absolute http(s) URL,
 * a `<span>` element otherwise
 */
export default {
  name: 'SafeLink',
  /*
    The props contain all attributes specifically defined for the <a> element:
    https://www.w3.org/TR/2011/WD-html5-20110113/text-level-semantics.html#the-a-element
   */
  props: {
    href: {
      type: String,
      required: true,
    },
    target: {
      type: String,
      required: false,
      default: undefined,
    },
    rel: {
      type: String,
      required: false,
      default: undefined,
    },
    media: {
      type: String,
      required: false,
      default: undefined,
    },
    hreflang: {
      type: String,
      required: false,
      default: undefined,
    },
    type: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    hasSafeHref() {
      return isSafeURL(this.href);
    },
    componentName() {
      return this.hasSafeHref ? 'a' : 'span';
    },
    linkAttributes() {
      if (this.hasSafeHref) {
        const { href, target, rel, media, hreflang, type } = this;
        return { href, target, rel, media, hreflang, type };
      }
      return {};
    },
  },
};
</script>
<template>
  <component
    :is="componentName"
    v-bind="linkAttributes"
  >
    <slot></slot>
  </component>
</template>
