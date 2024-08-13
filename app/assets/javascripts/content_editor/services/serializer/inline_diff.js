import { preserveUnchangedMark } from '../serialization_helpers';

const inlineDiff = preserveUnchangedMark({
  mixable: true,
  open(_, mark) {
    return mark.attrs.type === 'addition' ? '{+' : '{-';
  },
  close(_, mark) {
    return mark.attrs.type === 'addition' ? '+}' : '-}';
  },
});

export default inlineDiff;
