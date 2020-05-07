<script>
import {
  GlFilteredSearchToken,
  GlAvatar,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
} from '@gitlab/ui';
import { ANY_TRIGGER_AUTHOR } from '../../constants';

export default {
  anyTriggerAuthor: ANY_TRIGGER_AUTHOR,
  components: {
    GlFilteredSearchToken,
    GlAvatar,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    currentValue() {
      return this.value.data.toLowerCase();
    },
    filteredTriggerAuthors() {
      return this.config.triggerAuthors.filter(user => {
        return user.username.toLowerCase().includes(this.currentValue);
      });
    },
    activeUser() {
      return this.config.triggerAuthors.find(user => {
        return user.username.toLowerCase() === this.currentValue;
      });
    },
  },
};
</script>

<template>
  <gl-filtered-search-token :config="config" v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view="{inputValue}">
      <gl-avatar
        v-if="activeUser"
        :size="16"
        :src="activeUser.avatar_url"
        shape="circle"
        class="gl-mr-2"
      />
      <span>{{ activeUser ? activeUser.name : inputValue }}</span>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion :value="$options.anyTriggerAuthor">{{
        $options.anyTriggerAuthor
      }}</gl-filtered-search-suggestion>
      <gl-dropdown-divider />
      <gl-filtered-search-suggestion
        v-for="user in filteredTriggerAuthors"
        :key="user.username"
        :value="user.username"
      >
        <div class="d-flex">
          <gl-avatar :size="32" :src="user.avatar_url" />
          <div>
            <div>{{ user.name }}</div>
            <div>@{{ user.username }}</div>
          </div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
