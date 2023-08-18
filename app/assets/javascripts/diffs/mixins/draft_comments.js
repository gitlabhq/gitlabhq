// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { IMAGE_DIFF_POSITION_TYPE } from '../constants';

export default {
  computed: {
    ...mapGetters('batchComments', [
      'shouldRenderDraftRow',
      'shouldRenderParallelDraftRow',
      'draftsForLine',
      'draftsForFile',
      'hasParallelDraftLeft',
      'hasParallelDraftRight',
    ]),
    imageDiscussionsWithDrafts() {
      return this.diffFile.discussions
        .filter((f) => f.position?.position_type === IMAGE_DIFF_POSITION_TYPE)
        .concat(this.draftsForFile(this.diffFile.file_hash));
    },
  },
};
