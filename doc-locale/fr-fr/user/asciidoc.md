---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez des fichiers AsciiDoc dans votre projet GitLab et comprenez la syntaxe AsciiDoc.
title: AsciiDoc
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab utilise le gem [Asciidoctor](https://asciidoctor.org) pour convertir le contenu AsciiDoc en HTML5. Pour une référence complète, consultez le [manuel utilisateur Asciidoctor](https://asciidoctor.org/docs/user-manual/).

Vous pouvez utiliser AsciiDoc dans les zones suivantes :

- Les pages wiki
- Documents AsciiDoc (`.adoc` ou `.asciidoc`) dans les dépôts

## Paragraphes {#paragraphs}

```plaintext
A normal paragraph.
Line breaks are not preserved.
```

Les commentaires de ligne, qui sont des lignes commençant par `//`, sont ignorés :

```plaintext
// this is a comment
```

Une ligne vide sépare les paragraphes.

Un paragraphe avec l'option `[%hardbreaks]` préserve les sauts de ligne :

```plaintext
[%hardbreaks]
This paragraph carries the `hardbreaks` option.
Notice how line breaks are now preserved.
```

Un paragraphe indenté (littéral) désactive la mise en forme du texte, préserve les espaces et les sauts de ligne, et s'affiche dans une police à largeur fixe :

```plaintext
 This literal paragraph is indented with one space.
 As a consequence, *text formatting*, spaces,
 and lines breaks will be preserved.
```

Les paragraphes d'avertissement attirent l'attention du lecteur :

- `NOTE: This is a brief reference, read the full documentation at https://asciidoctor.org/docs/.`
- `TIP: Lists can be indented. Leading whitespace is not significant.`

## Mise en forme du texte {#text-formatting}

- Contraint (appliqué aux limites de mots) :

  ```plaintext
  *strong importance* (aka bold)
  _stress emphasis_ (aka italic)
  `monospaced` (aka typewriter text)
  "`double`" and '`single`' typographic quotes
  +passthrough text+ (substitutions disabled)
  `+literal text+` (monospaced with substitutions disabled)
  ```

- Non contraint (appliqué partout) :

  ```plaintext
  **C**reate+**R**ead+**U**pdate+**D**elete
  fan__freakin__tastic
  ``mono``culture
  ```

- Remplacements :

  ```plaintext
  A long time ago in a galaxy far, far away...
  (C) 1976 Arty Artisan
  I believe I shall--no, actually I won't.
  ```

- Macros :

  ```plaintext
  // where c=specialchars, q=quotes, a=attributes, r=replacements, m=macros, p=post_replacements
  The European icon:flag[role=blue] is blue & contains pass:[************] arranged in a icon:circle-o[role=yellow].
  The pass:c[->] operator is often referred to as the stabby lambda.
  Since `pass:[++]` has strong priority in AsciiDoc, you can rewrite pass:c,a,r[C++ => C{pp}].
  // activate stem support by adding `:stem:` to the document header
  stem:[sqrt(4) = 2]
  ```

## Liens {#links}

```plaintext
https://example.org/page[A webpage]
link:../path/to/file.txt[A local file]
xref:document.adoc[A sibling document]
mailto:hello@example.org[Email to say hello!]
```

## Ancres {#anchors}

```plaintext
[[idname,reference text]]
// or written using normal block attributes as `[#idname,reftext=reference text]`
A paragraph (or any block) with an anchor (aka ID) and reftext.

See <<idname>> or <<idname,optional text of internal link>>.

xref:document.adoc#idname[Jumps to anchor in another document].

This paragraph has a footnote.footnote:[This is the text of the footnote.]
```

## Listes {#lists}

### Non ordonné {#unordered}

```plaintext
* level 1
** level 2
*** level 3
**** level 4
***** level 5
* back at level 1
+
Attach a block or paragraph to a list item using a list continuation (which you can enclose in an open block).

.Some Authors
[circle]
- Edgar Allen Poe
- Sheri S. Tepper
- Bill Bryson
```

### Ordonné {#ordered}

```plaintext
. Step 1
. Step 2
.. Step 2a
.. Step 2b
. Step 3

.Remember your Roman numerals?
[upperroman]
. is one
. is two
. is three
```

### Liste de contrôle {#checklist}

```plaintext
* [x] checked
* [ ] not checked
```

### Légende {#callout}

```plaintext
// enable callout bubbles by adding `:icons: font` to the document header
[,ruby]
----
puts 'Hello, World!' # <1>
----
<1> Prints `Hello, World!` to the console.
```

### Description {#description}

```plaintext
first term:: description of first term
second term::
description of second term
```

## En-têtes {#headers}

```plaintext
= Document Title
Author Name <author@example.org>
v1.0, 2019-01-01
```

## Sections {#sections}

```plaintext
= Document Title (Level 0)
== Level 1
=== Level 2
==== Level 3
===== Level 4
====== Level 5
== Back at Level 1
```

## Includes {#includes}

> [!note]
> Les [pages wiki](project/wiki/_index.md#create-a-new-wiki-page) créées avec le format AsciiDoc sont enregistrées avec l'extension de fichier `.asciidoc`. Lorsque vous travaillez avec des pages wiki AsciiDoc, remplacez l'extension du nom de fichier `.adoc` par `.asciidoc`.

```plaintext
include::basics.adoc[]
```

```plaintext
// you can also include other files from you repository
[,language]
----
include::my_code_file.language[]
----
```

Pour garantir de bonnes performances système et empêcher des documents malveillants de causer des problèmes, GitLab applique une limite maximale sur le nombre de directives d'inclusion traitées dans un document. Par défaut, un document peut contenir jusqu'à 32 directives d'inclusion, ce qui inclut les dépendances transitives. Pour personnaliser le nombre de directives d'inclusion traitées, modifiez le paramètre d'application `asciidoc_max_includes` via l'[API des paramètres d'application](../api/settings.md#available-settings).

> [!note]
> La valeur maximale autorisée pour `asciidoc_max_includes` est 64. Si la valeur est trop élevée, cela peut entraîner des problèmes de performances dans certaines situations.

Pour utiliser des inclusions depuis des pages séparées ou des URL externes, activez `allow-uri-read` dans les [paramètres d'application](../administration/wikis/_index.md#allow-uri-includes-for-asciidoc).

```plaintext
// define application setting allow-uri-read to true to allow content to be read from URI
include::https://example.org/installation.adoc[]
```

## Attributs {#attributes}

### Défini par l'utilisateur {#user-defined}

```plaintext
// define attributes in the document header
:name: value
```

```plaintext
:url-gem: https://rubygems.org/gems/asciidoctor

You can download and install Asciidoctor {asciidoctor-version} from {url-gem}.
C{pp} is not required, only Ruby.
Use a leading backslash to output a word enclosed in curly braces, like \{name}.
```

### Environnement {#environment}

GitLab définit les attributs d'environnement suivants :

| Attribut       | Description                                                                                                            |
| :-------------- | :--------------------------------------------------------------------------------------------------------------------- |
| `docname`       | Nom racine du document source (sans chemin d'accès ni extension de fichier).                                                  |
| `outfilesuffix` | Extension de fichier correspondant à la sortie du backend (par défaut `.adoc` pour que les références croisées entre documents fonctionnent). |

## Blocs {#blocks}

```plaintext
--
open - a general-purpose content wrapper; useful for enclosing content to attach to a list item
--
```

```plaintext
// recognized types include CAUTION, IMPORTANT, NOTE, TIP, and WARNING
// enable admonition icons by setting `:icons: font` in the document header
[NOTE]
====
admonition - a notice for the reader, ranging in severity from a tip to an alert
====
```

```plaintext
====
example - a demonstration of the concept being documented
====
```

```plaintext
.Toggle Me
[%collapsible]
====
collapsible - these details are revealed by clicking the title
====
```

```plaintext
****
sidebar - auxiliary content that can be read independently of the main content
****
```

```plaintext
....
literal - an exhibit that features program output
....
```

```plaintext
----
listing - an exhibit that features program input, source code, or the contents of a file
----
```

```plaintext
[,language]
----
source - a listing that is embellished with (colorized) syntax highlighting
----
```

````plaintext
\```language
fenced code - a shorthand syntax for the source block
\```
````

```plaintext
[,attribution,citetitle]
____
quote - a quotation or excerpt; attribution with title of source are optional
____
```

```plaintext
[verse,attribution,citetitle]
____
verse - a literary excerpt, often a poem; attribution with title of source are optional
____
```

```plaintext
++++
pass - content passed directly to the output document; often raw HTML
++++
```

```plaintext
// activate stem support by adding `:stem:` to the document header
[stem]
++++
x = y^2
++++
```

```plaintext
////
comment - content which is not included in the output document
////
```

## Tableaux {#tables}

```plaintext
.Table Attributes
[cols=>1h;2d,width=50%,frame=topbot]
|===
| Attribute Name | Values

| options
| header,footer,autowidth

| cols
| colspec[;colspec;...]

| grid
| all \| cols \| rows \| none

| frame
| all \| sides \| topbot \| none

| stripes
| all \| even \| odd \| none

| width
| (0%..100%)

| format
| psv {vbar} csv {vbar} dsv
|===
```

## Couleurs {#colors}

Il est possible d'afficher une couleur écrite au format `HEX`, `RGB` ou `HSL` avec un indicateur de couleur. Formats pris en charge (les couleurs nommées ne sont pas prises en charge) :

- `HEX` : `` `#RGB[A]` `` ou `` `#RRGGBB[AA]` ``
- `RGB` : `` `RGB[A](R, G, B[, A])` ``
- `HSL` : `` `HSL[A](H, S, L[, A])` ``

Une couleur écrite entre guillemets inversés est suivie d'une « puce » de couleur :

```plaintext
- `#F00`
- `#F00A`
- `#FF0000`
- `#FF0000AA`
- `RGB(0,255,0)`
- `RGB(0%,100%,0%)`
- `RGBA(0,255,0,0.3)`
- `HSL(540,70%,50%)`
- `HSLA(540,70%,50%,0.3)`
```

## Équations et formules {#equations-and-formulas}

Si vous avez besoin d'inclure des expressions scientifiques, technologiques, d'ingénierie et mathématiques (STEM), définissez l'attribut `stem` dans l'en-tête du document sur `latexmath`. Les équations et formules sont rendues à l'aide de [KaTeX](https://katex.org/) :

```plaintext
:stem: latexmath

latexmath:[C = \alpha + \beta Y^{\gamma} + \epsilon]

[stem]
++++
sqrt(4) = 2
++++

A matrix can be written as stem:[[[a,b\],[c,d\]\]((n),(k))].
```

## Diagrammes et organigrammes {#diagrams-and-flowcharts}

Il est possible de générer des diagrammes et des organigrammes à partir de texte dans GitLab en utilisant [Mermaid](https://mermaidjs.github.io/) ou [PlantUML](https://plantuml.com).

### Mermaid {#mermaid}

Visitez la [page officielle](https://mermaidjs.github.io/) pour plus de détails. Si vous débutez avec Mermaid ou avez besoin d'aide pour identifier des problèmes dans votre code Mermaid, le [Mermaid Live Editor](https://mermaid-js.github.io/mermaid-live-editor/) est un outil utile pour créer et résoudre des problèmes dans les diagrammes Mermaid.

Pour générer un diagramme ou un organigramme, saisissez votre texte dans un bloc `mermaid` :

```plaintext
[mermaid]
----
graph LR
    A[Square Rect] -- Link text --> B((Circle))
    A --> C(Round Rect)
    B --> D{Rhombus}
    C --> D
----
```

### Kroki {#kroki}

Kroki prend en charge plus d'une douzaine de bibliothèques de diagrammes. Pour rendre Kroki disponible dans GitLab, un administrateur GitLab doit d'abord l'activer. Pour en savoir plus, consultez la page [Intégration Kroki](../administration/integration/kroki.md).

Une fois Kroki activé, vous pouvez créer des diagrammes dans des documents AsciiDoc et Markdown. Voici un exemple utilisant un diagramme GraphViz :

- AsciiDoc :

  ```plaintext
  [graphviz]
  ....
  digraph G {
    Hello->World
  }
  ....
  ```

- Markdown :

  ````markdown
  ```graphviz
  digraph G {
    Hello->World
  }
  ```
  ````

### PlantUML {#plantuml}

L'intégration PlantUML est activée sur GitLab.com. Pour rendre PlantUML disponible dans une installation GitLab Self-Managed de GitLab, un administrateur GitLab [doit l'activer](../administration/integration/plantuml.md).

Une fois PlantUML activé, saisissez votre texte dans un bloc `plantuml` :

```plaintext
[plantuml]
----
Bob -> Alice : hello
----
```

Pour inclure des diagrammes PlantUML stockés dans des fichiers séparés :

```plaintext
[plantuml, format="png", id="myDiagram", width="200px"]
----
include::diagram.puml[]
----
```

## Multimédia {#multimedia}

```plaintext
image::screenshot.png[block image,800,450]

Press image:reload.svg[reload,16,opts=interactive] to reload the page.

video::movie.mp4[width=640,start=60,end=140,options=autoplay]
```

GitLab ne prend pas en charge l'intégration de vidéos YouTube et Vimeo dans le contenu AsciiDoc. Utilisez un lien AsciiDoc standard :

```plaintext
https://www.youtube.com/watch?v=BlaZ65-b7y0[Link text for the video]
```

## Sauts {#breaks}

```plaintext
// thematic break (aka horizontal rule)
---
```

```plaintext
// page break
<<<
```

## Table des matières {#table-of-contents}

```plaintext
= Document Title (Level 0)
:toc:
:toclevels: 3
:toc-title: Contents

== Level 1
=== Level 2
==== Level 3
===== Level 4
====== Level 5
== Back at Level 1
```

Les attributs `:toc-class:`, `:toc: left` et `:toc: right` ne sont pas pris en charge.
