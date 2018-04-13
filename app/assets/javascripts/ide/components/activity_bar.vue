<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import ExternalLinks from './ide_external_links.vue';
import { ActivityBarViews } from '../stores/state';

export default {
  components: {
    Icon,
    ExternalLinks,
  },
  computed: {
    ...mapGetters(['currentProject']),
    ...mapState(['currentActivityView']),
  },
  methods: {
    ...mapActions(['updateActivityBarView']),
  },
  ActivityBarViews,
};
</script>

<template>
  <nav class="ide-activity-bar">
    <ul class="list-unstyled">
      <li>
        <external-links
          class="ide-activity-bar-link"
          :project-url="currentProject.web_url"
        />
      </li>
      <li>
        <a
          href="#"
          class="ide-sidebar-link ide-activity-bar-link"
          :class="{
            active: currentActivityView === $options.ActivityBarViews.edit
          }"
          @click.prevent="updateActivityBarView($options.ActivityBarViews.edit)"
        >
          <icon
            :size="16"
            name="code"
          />
        </a>
      </li>
      <li>
        <a
          href="#"
          class="ide-sidebar-link ide-activity-bar-link"
          :class="{
            active: currentActivityView === $options.ActivityBarViews.commit
          }"
          @click.prevent="updateActivityBarView($options.ActivityBarViews.commit)"
        >
          <icon
            :size="16"
            name="commit"
          />
        </a>
      </li>
    </ul>
  </nav>
</template>

<style>
.ide-activity-bar {
  position: relative;
  flex: 0 0 60px;
  z-index: 2;
}

.ide-activity-bar-link {
  position: relative;
  height: 55px;
  margin: 2.5px 0;
  color: #707070;
  border-top: 1px solid transparent;
  border-bottom: 1px solid transparent;
}

.ide-activity-bar-link svg {
  margin: 0 auto;
  fill: currentColor;
}

.ide-activity-bar-link.active {
  color: #4b4ba3;
  background-color: #fff;
  border-top: 1px solid #eaeaea;
  border-bottom: 1px solid #eaeaea;
  box-shadow: inset 3px 0 #4b4ba3;
}

a.ide-sidebar-link.ide-activity-bar-link.active::after {
  content: '';
  position: absolute;
  right: -1px;
  top: 0;
  bottom: 0;
  width: 1px;
  background: #fff;
}

.ide-activity-bar-link:hover {
  color: #4b4ba3;
  background-color: #fff;
}
</style>
