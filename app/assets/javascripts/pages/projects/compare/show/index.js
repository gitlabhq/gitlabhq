import initCompareSelector from '~/projects/compare';
import GpgBadges from '~/gpg_badges';
import { createRapidDiffsApp } from '~/rapid_diffs';

initCompareSelector();
GpgBadges.fetch();

const app = createRapidDiffsApp();
app.init();
