<script>
/* eslint-disable vue/no-v-html */
// We are forced to use `v-html` untill this gitlab-ui MR is merged: https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/1869
//  then we can re-write this to use gl-breadcrumb
import { initial, first, last } from 'lodash';
import { sanitize } from '~/lib/dompurify';

export default {
  props: {
    crumbs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    parsedCrumbs() {
      return this.crumbs.map(c => ({ ...c, innerHTML: sanitize(c.innerHTML) }));
    },
    rootRoute() {
      return this.$router.options.routes.find(r => r.meta.root);
    },
    isRootRoute() {
      return this.$route.name === this.rootRoute.name;
    },
    rootCrumbs() {
      return initial(this.parsedCrumbs);
    },
    divider() {
      const { classList, tagName, innerHTML } = first(this.crumbs).querySelector('svg');
      return { classList: [...classList], tagName, innerHTML: sanitize(innerHTML) };
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
      :class="crumb.className"
      v-html="crumb.innerHTML"
    ></li>
    <li v-if="!isRootRoute">
      <router-link ref="rootRouteLink" :to="rootRoute.path">
        {{ rootRoute.meta.nameGenerator($store.state) }}
      </router-link>
      <component :is="divider.tagName" :class="divider.classList" v-html="divider.innerHTML" />
    </li>
    <li>
      <component :is="lastCrumb.tagName" ref="lastCrumb" :class="lastCrumb.className">
        <router-link ref="childRouteLink" :to="lastCrumb.path">{{ lastCrumb.text }}</router-link>
      </component>
    </li>
  </ul>
</template>
