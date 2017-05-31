<script>
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
import IssueList from './issue_list.vue';

export default {
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
  components: {
    userAvatarImage,
    IssueList,
  }
}
</script>
<template>

  <div class="panel panel-default">
    <div class="panel-heading">
      <div class="title">
        <h4>
        <user-avatar-image :img-src="data.avatar_url" :size="40"/> {{data.name}}
        <small v-if="data.status" class="text-muted"> - {{data.status}}</small>
        <div><small>{{data.deliverables.length}} Deliverables<template v-if="data.issues.length>0"> / {{data.issues.length}} Issues</template></small></div>
      </h4>
      </div>
    </div>
    <IssueList :issues="data.deliverables"/>
  </div>
</template>
