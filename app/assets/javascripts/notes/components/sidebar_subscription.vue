<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import { confidentialityQueries } from '~/sidebar/queries/constants';
import { defaultClient as gqlClient } from '~/graphql_shared/issuable_client';

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
    if (this.issuableType !== TYPE_ISSUE && this.issuableType !== TYPE_EPIC) {
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
