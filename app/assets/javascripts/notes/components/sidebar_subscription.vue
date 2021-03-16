<script>
import { mapActions } from 'vuex';
import { IssuableType } from '~/issue_show/constants';
import { fetchPolicies } from '~/lib/graphql';
import { confidentialityQueries } from '~/sidebar/constants';
import { defaultClient as gqlClient } from '~/sidebar/graphql';

export default {
  props: {
    noteableData: {
      type: Object,
      required: true,
    },
    iid: {
      type: Number,
      required: true,
    },
  },
  computed: {
    fullPath() {
      if (this.noteableData.web_url) {
        return this.noteableData.web_url.split('/-/')[0].substring(1).replace('groups/', '');
      }
      return null;
    },
    issuableType() {
      return this.noteableData.noteableType.toLowerCase();
    },
  },
  created() {
    if (this.issuableType !== IssuableType.Issue && this.issuableType !== IssuableType.Epic) {
      return;
    }

    gqlClient
      .watchQuery({
        query: confidentialityQueries[this.issuableType].query,
        variables: {
          iid: String(this.iid),
          fullPath: this.fullPath,
        },
        fetchPolicy: fetchPolicies.CACHE_ONLY,
      })
      .subscribe((res) => {
        const issuable = res.data?.workspace?.issuable;
        if (issuable) {
          this.setConfidentiality(issuable.confidential);
        }
      });
  },
  methods: {
    ...mapActions(['setConfidentiality']),
  },
  render() {
    return null;
  },
};
</script>
