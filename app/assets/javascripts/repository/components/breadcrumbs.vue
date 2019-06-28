<script>
import getRefMixin from '../mixins/get_ref';
import getProjectShortPath from '../queries/getProjectShortPath.query.graphql';

export default {
  apollo: {
    projectShortPath: {
      query: getProjectShortPath,
    },
  },
  mixins: [getRefMixin],
  props: {
    currentPath: {
      type: String,
      required: false,
      default: '/',
    },
  },
  data() {
    return {
      projectShortPath: '',
    };
  },
  computed: {
    pathLinks() {
      return this.currentPath
        .split('/')
        .filter(p => p !== '')
        .reduce(
          (acc, name, i) => {
            const path = `${i > 0 ? acc[i].path : ''}/${name}`;

            return acc.concat({
              name,
              path,
              to: `/tree/${this.ref}${path}`,
            });
          },
          [{ name: this.projectShortPath, path: '/', to: `/tree/${this.ref}/` }],
        );
    },
  },
  methods: {
    isLast(i) {
      return i === this.pathLinks.length - 1;
    },
  },
};
</script>

<template>
  <nav :aria-label="__('Files breadcrumb')">
    <ol class="breadcrumb repo-breadcrumb">
      <li v-for="(link, i) in pathLinks" :key="i" class="breadcrumb-item">
        <router-link :to="link.to" :aria-current="isLast(i) ? 'page' : null">
          {{ link.name }}
        </router-link>
      </li>
    </ol>
  </nav>
</template>
