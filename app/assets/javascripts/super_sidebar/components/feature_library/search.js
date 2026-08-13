// Search-result ranking, best first. A title match beats a synonym-only match,
// which beats a description-only match.
const RANK_TITLE_EXACT = 0;
const RANK_TITLE_PREFIX = 1;
const RANK_TITLE_CONTAINS = 2;
const RANK_SYNONYM = 3;
const RANK_DESCRIPTION = 4;

/**
 * Rank and sort catalog items for a search query.
 *
 * Items are grouped into tiers by match quality and ordered within each tier:
 * title tiers prefer the shorter (tighter) title, the synonym tier keeps the
 * endpoint's exact-term-first order, and the description tier stays A-Z.
 *
 * @param {Object} options
 * @param {Array<Object>} options.catalog - All catalog items ({ id, title, description, ... }).
 * @param {string} options.query - The trimmed, non-empty search query.
 * @param {Array<string>} options.synonymIds - Item ids returned by the search
 *   endpoint, already backend-ranked (exact term -> prefix -> contains).
 * @returns {Array<Object>} Matching catalog items, ranked and sorted.
 */
export function rankSearchResults({ catalog, query, synonymIds = [] }) {
  const q = query.toLowerCase();
  const catalogById = Object.fromEntries(catalog.map((item) => [item.id, item]));

  const synonymMatches = synonymIds.map((id) => catalogById[id]).filter((item) => item);
  const endpointRank = new Map(synonymMatches.map((item, index) => [item.id, index]));

  const matchedSynonymIds = new Set(synonymMatches.map((item) => item.id));
  const textMatches = (text = '') => text.toLowerCase().includes(q);
  const directMatches = catalog.filter(
    (item) =>
      !matchedSynonymIds.has(item.id) && (textMatches(item.title) || textMatches(item.description)),
  );

  const rankOf = (item) => {
    const title = item.title.toLowerCase();

    if (title === q) return RANK_TITLE_EXACT;
    if (title.startsWith(q)) return RANK_TITLE_PREFIX;
    if (title.includes(q)) return RANK_TITLE_CONTAINS;

    return matchedSynonymIds.has(item.id) ? RANK_SYNONYM : RANK_DESCRIPTION;
  };

  const ranked = [...synonymMatches, ...directMatches].map((item) => ({
    item,
    rank: rankOf(item),
  }));

  ranked.sort((a, b) => {
    if (a.rank !== b.rank) return a.rank - b.rank;

    if (a.rank <= RANK_TITLE_CONTAINS && a.item.title.length !== b.item.title.length) {
      return a.item.title.length - b.item.title.length;
    }

    if (a.rank === RANK_SYNONYM) {
      return endpointRank.get(a.item.id) - endpointRank.get(b.item.id);
    }

    return a.item.title.localeCompare(b.item.title);
  });

  return ranked.map(({ item }) => item);
}
