<script>
import { initial, first, last } from 'lodash';

export default {
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
      const { tagName, classList } = first(children);
      return {
        tagName,
        classList: [...classList],
        text: this.$route.meta.nameGenerator(this.$route),
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
      :class="crumb.classList"
      v-html="crumb.innerHTML"
    ></li>
    <li v-if="!isRootRoute">
      <router-link ref="rootRouteLink" :to="rootRoute.path">
        {{ rootRoute.meta.nameGenerator(rootRoute) }}
      </router-link>
      <component :is="divider.tagName" :class="divider.classList" v-html="divider.innerHTML" />
    </li>
    <li>
      <component :is="lastCrumb.tagName" ref="lastCrumb" :class="lastCrumb.classList">
        <router-link ref="childRouteLink" :to="lastCrumb.path">{{ lastCrumb.text }}</router-link>
      </component>
    </li>
  </ul>
</template>
