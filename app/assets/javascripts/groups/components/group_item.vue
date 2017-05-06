<script>
export default {
  props: {
    group: {
      type: Object,
      required: true,
    }    
  }
};
</script>

<template>
  <tr>
    <td>
      <div>
        <a :href="group.web_url">{{group.full_name}}</a>
      </div>
      <div>{{group.description}}</div>
    </td>
  </tr>
</template>
