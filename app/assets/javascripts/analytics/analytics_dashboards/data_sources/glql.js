/**
 * Passes a GLQL query string straight through to the visualization.
 *
 * Unlike other data sources, GLQL panels don't fetch data here — the
 * `GlqlResolver` rendered by the `Glql` visualization parses and executes
 * the query itself. This source simply surfaces the query string (stored in
 * the panel's `data.query`) as the `data` prop the visualization receives.
 */
export default function fetch({ query: { glql = '' } = {} } = {}) {
  return glql;
}
