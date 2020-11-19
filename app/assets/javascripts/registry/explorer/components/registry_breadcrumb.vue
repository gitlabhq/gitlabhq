<script>
import { initial, first, last } from 'lodash';
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';

export default {
  directives: { SafeHtml },
  props: {
    crumbs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    rootRoute() {
      return this.$router.options.routes.find(r => r.meta.root);
    },
    isRootRoute() {
      return this.$route.name === this.rootRoute.name;
    },
    rootCrumbs() {
      return initial(this.crumbs);
    },
    divider() {
      const { classList, tagName, innerHTML } = first(this.crumbs).querySelector('svg');
      return { classList: [...classList], tagName, innerHTML };
    },
    lastCrumb() {
      const { children } = last(this.crumbs);
      const { tagName, className } = first(children);
      return {
        tagName,
        className,
        text: this.$route.meta.nameGenerator(this.$store.state),
        path: { to: this.$route.name },
      };
    },
  },
};
</script>

<template>
  <ul>
    <li
      v-for="(crumb, index) in rootCrumbs"
      :key="index"
      v-safe-html="crumb.innerHTML"
      :class="crumb.className"
    ></li>
    <li v-if="!isRootRoute">
      <router-link ref="rootRouteLink" :to="rootRoute.path">
        {{ rootRoute.meta.nameGenerator($store.state) }}
      </router-link>
      <component :is="divider.tagName" v-safe-html="divider.innerHTML" :class="divider.classList" />
    </li>
    <li>
      <component :is="lastCrumb.tagName" ref="lastCrumb" :class="lastCrumb.className">
        <router-link ref="childRouteLink" :to="lastCrumb.path">{{ lastCrumb.text }}</router-link>
      </component>
    </li>
  </ul>
</template>
